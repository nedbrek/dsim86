module alu;

import archstate;
import inst;
import std.string;

private:
alias ulong function(ArchState a, Inst86.MemType mt, in MemSpec *ops)
   AluFun;

ulong add(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong adc(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong and(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong xor(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong or(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong sbb(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong sub(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

ulong cmp(ArchState a, Inst86.MemType mt, in MemSpec *ops)
{
	return 0;
}

class AluOp : Inst86
{
	MemSpec  ops_;
	MemType  mt_;
	ubyte    op_;
	OpSz     sz_;

	static AluFun[8] funcs = [
		&add, &or,  &adc, &sbb,
		&and, &sub, &xor, &cmp
	];

	static char[3] names[8] = [
		"add", "or ", "adc", "sbb",
		"and", "sub", "xor", "cmp"
	];

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		op_ = cast(ubyte)((op >> 3) & 7);

		// bit0 -> b(0) : v(1)
		if( op & 1 )
		{
			// vord
			if( p.rex.W )
			{
				sz_ = OpSz.QWORD;
			}
			else
			{
				bool use16 = true;
				if( p.wordOver )
				{
					use16 = false;
				}

				sz_ = use16 ? OpSz.WORD : OpSz.DWORD;
			}
		}
		else
		{
			sz_ = OpSz.BYTE;
		}

		switch( op & 6 )
		{
		case 0: // mr
		case 2: // rm
			mt_ = (op & 6) ? MemType.READ : MemType.RMW;
			ops_.mrm.all = a.getNextIByte();
			switch( ops_.mrm.mod )
			{
			case 0: // no offset, except BP(6)
				if( ops_.mrm.rm == 6 )
					ops_.imm = getIword(a);
				break;

			case 1: // 8b
				ops_.imm = a.getNextIByte();
				break;

			case 2: // 16b
				ops_.imm = getIword(a);
				break;

			default:
			}
			break;

		case 4: // ai
			mt_ = MemType.NONE;
			if( sz_ == OpSz.BYTE )
			{
				ops_.imm = a.getNextIByte();
			}
			else
			{
				ops_.imm = getIword(a);
			}
			break;

		default:
			assert(false);
		}
	}

	MemType getMemType() { return mt_; }
	MemSpec getMemRef()  { return ops_; }

	uint numDst() { return 1; }
	uint numSrc() { return 2; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		ulong res = funcs[op_](a, mt_, &ops_);
		// compute flags on result
	}

	void disasm(ArchState a, out char[] str)
	{
		str = names[op_];
		str ~= " ";
		str ~= std.string.toString(cast(ulong)ops_.mrm.all, 16u);
	}
}

public Inst86 aluFun(Prefixes *p, ubyte op, ArchState a)
{
	AluOp ret = new AluOp;
	ret.init(p, op, a);

	return ret;
}

