module mov;

import archstate;
import inst;
import operand;

class MovInst : Inst86
{
	Operand dst_;
	Operand src_;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		// mov +r = i
		if( 0xb0 <= op && op <= 0xbf )
		{
			OpSz sz = OpSz.BYTE;
			if( op > 0xb7 )
			{
				//Ned, DWORD
				sz = OpSz.WORD;

				src_ = new ImmOp(getIword(a));
			}
			else
			{
				src_ = new ImmOp(a.getNextIByte());
			}

			dst_ = new RegOp(RegSet.GP, cast(ubyte)(op & 7), sz);
		}

		// mov reg and mem
		if( 0x88 <= op && op <= 0x8b )
		{
			OpSz sz = OpSz.BYTE;
			if( op & 1 )
			{
				//Ned, DWORD
				sz = OpSz.WORD;
			}

			ByteModRM mrm;
			mrm.all = a.getNextIByte();
			auto reg = new RegOp(RegSet.GP, mrm.reg, sz);

			auto rm = decodeMRM(a, mrm, sz, OpMode.MD16);

			if( op & 2 )
			{
				// reg = mem
				dst_ = reg;
				src_ = rm;
			}
			else
			{
				// mem = reg
				dst_ = rm;
				src_ = reg;
			}
		}
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint numDst() { return 1; }
	uint numSrc() { return 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		dst_.write(a, src_.read(a));
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= "mov ";
		dst_.disasm(str);
		str ~= ", ";
		src_.disasm(str);
	}
}

Inst86 movF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new MovInst;
	ret.init(p, op, a);

	return ret;
}

