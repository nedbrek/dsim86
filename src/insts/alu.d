module alu;

import archstate;
import inst;
import operand;
import std.string;

private:
alias ulong function(ArchState a, Operand dst, Operand src)
   AluFun;

ulong add(ArchState a, Operand dst, Operand src)
{
	ulong ret = dst.read(a) + src.read(a);
	dst.write(a, ret);
	return ret;
}

ulong adc(ArchState a, Operand dst, Operand src)
{
	return 0;
}

ulong and(ArchState a, Operand dst, Operand src)
{
	return 0;
}

ulong xor(ArchState a, Operand dst, Operand src)
{
	ulong ret = dst.read(a) ^ src.read(a);
	dst.write(a, ret);
	return ret;
}

ulong or(ArchState a, Operand dst, Operand src)
{
	return 0;
}

ulong sbb(ArchState a, Operand dst, Operand src)
{
	return 0;
}

ulong sub(ArchState a, Operand dst, Operand src)
{
	return 0;
}

ulong cmp(ArchState a, Operand dst, Operand src)
{
	ulong tmp = dst.read(a);
	tmp -= src.read(a);
	return tmp;
}

ulong test(ArchState a, Operand dst, Operand src)
{
	return 0;
}

class AluOp : Inst86
{
	Operand dst_;
	Operand src_;
	ubyte    op_;

	static AluFun[9] funcs = [
		&add, &or,  &adc, &sbb,
		&and, &sub, &xor, &cmp, &test
	];

	static char[3] names[9] = [
		"add", "or ", "adc", "sbb",
		"and", "sub", "xor", "cmp", "tst"
	];

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		bool use16 = true; //Ned check
		if( p.wordOver )
		{
			use16 = false;
		}
		OpSz sz;

		// test
		if( op == 0xa8 || op == 0xa9 )
		{
			// test a, i
			op_ = 8;
			sz = op & 1 ? OpSz.WORD : OpSz.BYTE;

			dst_ = new RegOp(RegSet.GP, 0, sz);

			if( sz == OpSz.BYTE )
			{
				src_ = new ImmOp(a.getNextIByte());
			}
			else
			{
				src_ = new ImmOp(getIword(a));
			}

			return;
		}
		else if( op == 0x84 || op == 0x85 )
		{
			// test rm, r
			op_ = 8;
			sz = op & 1 ? OpSz.WORD : OpSz.BYTE;

			ByteModRM mrm;
			mrm.all = a.getNextIByte();
			dst_  = decodeMRM(a, mrm, sz, OpMode.MD16);

			src_ = new RegOp(RegSet.GP, mrm.reg, sz);

			return;
		}
		else if( op == 0xf6 || op == 0xf7 )
		{
			// test rm, i
			op_ = 8;
			sz = op & 1 ? OpSz.WORD : OpSz.BYTE;

			ByteModRM mrm;
			mrm.all = a.getNextIByte();
			dst_  = decodeMRM(a, mrm, sz, OpMode.MD16);

			if( sz == OpSz.BYTE )
			{
				src_ = new ImmOp(a.getNextIByte());
			}
			else
			{
				src_ = new ImmOp(getIword(a));
			}

			return;
		}

		// rm, imm
		if( 0x80 <= op && op <= 0x83 )
		{
			// determine reg size
			if( op == 0x80 )
				sz = OpSz.BYTE;
			else if( p.rex.W )
				sz = OpSz.QWORD;
			else
				sz = use16 ? OpSz.WORD : OpSz.DWORD;

			// handle /r
			ByteModRM mrm;
			mrm.all = a.getNextIByte();

			op_ = mrm.reg;

			dst_  = decodeMRM(a, mrm, sz, OpMode.MD16);

			// handle imm
			if( op == 0x81 )
				src_ = new ImmOp(getIword(a));
			else
			{
				ulong imm = a.getNextIByte();
				if( op == 0x83 )
					imm = signEx(imm, OpSz.BYTE, OpSz.WORD);

				src_ = new ImmOp(imm);
			}

			return;
		}

		op_ = cast(ubyte)((op >> 3) & 7);

		// bit0 -> b(0) : v(1)
		if( op & 1 )
		{
			// vord
			if( p.rex.W )
			{
				sz = OpSz.QWORD;
			}
			else
			{
				sz = use16 ? OpSz.WORD : OpSz.DWORD;
			}
		}
		else
		{
			sz = OpSz.BYTE;
		}

		if( (op & 6) == 4 )
		{
			// ai
			dst_ = new RegOp(RegSet.GP, 0, sz);

			if( sz == OpSz.BYTE )
			{
				src_ = new ImmOp(a.getNextIByte());
			}
			else
			{
				src_ = new ImmOp(getIword(a));
			}

			return;
		}

		ByteModRM mrm;
		mrm.all = a.getNextIByte();

		auto reg = new RegOp(RegSet.GP, mrm.reg, sz);
		auto rm  = decodeMRM(a, mrm, sz, OpMode.MD16);

		switch( op & 6 )
		{
		case 0: // mr
			dst_ = rm;
			src_ = reg;
			break;

		case 2: // rm
			dst_ = reg;
			src_ = rm;
			break;

		default:
			assert(false);
		}
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef()  { MemSpec ret; return ret; }

	uint numDst() { return 1; }
	uint numSrc() { return 2; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		ulong res = funcs[op_](a, dst_, src_);
		// compute flags on result
		makeFlags(res, a);
	}

	void disasm(ArchState a, out char[] str)
	{
		str = names[op_];
		str ~= " ";
		dst_.disasm(str);
		str ~= ", ";
		src_.disasm(str);
	}
}

class LeaOp : Inst86
{
	Operand dst_;
	MemOp   src_;

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		OpSz dsz = OpSz.WORD;
		OpSz asz = OpSz.WORD;

		ByteModRM mrm;
		mrm.all = a.getNextIByte();

		dst_ = new RegOp(RegSet.GP, mrm.reg, dsz);
		src_ = cast(MemOp)(decodeMRM(a, mrm, asz, OpMode.MD16));
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef()  { MemSpec ret; return ret; }

	uint numDst() { return 1; }
	uint numSrc() { return 2; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		if( src_ )
			dst_.write(a, src_.getEA(a));
	}

	void disasm(ArchState a, out char[] str)
	{
	   str ~= "lea ";
	   dst_.disasm(str);
	   str ~= ", ";
	   src_.disasm(str);
	}
}

public:
Inst86 aluFun(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new AluOp;
	ret.init(p, op, a);

	return ret;
}

Inst86 leaF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new LeaOp;
	ret.init(p, op, a);

	return ret;
}

