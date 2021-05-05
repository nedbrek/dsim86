module sft;

import archstate;
import inst;
import operand;
import std.string;

class SftI : Inst86
{
protected:
	Operand dst_;
	Operand src_;
	ubyte op_;

	static char[3] names[8] = [
		"rol", "ror", "rcl", "rcr",
		"shl", "shr", "sal", "sar"
	];

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		ByteModRM mrm;
		mrm.all = a.getNextIByte();
		op_ = mrm.reg;

		bool use16 = true; //Ned check
		if( p.wordOver )
		{
			use16 = false;
		}

		OpSz sz;
		if( op & 1 )
		{
			if( p.rex.W )
				sz = OpSz.QWORD;
			else
				sz = use16 ? OpSz.WORD : OpSz.DWORD;
		}
		else
			sz = OpSz.BYTE;

		dst_  = decodeMRM(a, mrm, sz, OpMode.MD16);

		if( op & 2 ) // CL
		{
			src_ = new RegOp(RegSet.GP, RegBytes.CL, OpSz.BYTE);
		}
		else // imm 1
		{
			src_ = new ImmOp(1);
		}
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDst() { return 1; }
	uint    numSrc() { return 1; }

	ubyte getSrc(uint idx) { return 1; }
	ubyte getDst(uint idx) { return 1; }

	void execute(ArchState a)
	{
		ulong src = dst_.read(a);
		ulong amt = src_.read(a);
		switch (op_)
		{
		case 0: // ROL
		case 1: // ROR
		case 2: // RCL
		case 3: // RCR
			// TODO
			break;

		case 4: // SHL
			src <<= amt;
			break;

		case 5: // SHR
			src >>= amt;
			break;

		case 6: // (SAL)
			src = cast(short)(src) << amt;
			break;

		case 7: // SAR
			src = cast(short)(src) >> amt;
			break;

		default:;
		}

		dst_.write(a, src);
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

Inst86 sftI(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new SftI;
	ret.init(p, op, a);
	return ret;
}

