module io;

import archstate;
import inst;
import std.string;

class IoOp : Inst86
{
	ubyte imm_;
	bool  useDx_;
	bool  isOut_;
	OpSz  opSz_;

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		if( op & 1 )
		{
			opSz_ = OpSz.WORD;
		}
		else
		{
			opSz_ = OpSz.BYTE;
		}

		isOut_ = (op & 2) != 0;
		useDx_ = (op & 8) != 0;
		if( !useDx_ )
		{
			imm_ = a.getNextIByte();
		}
	}

	MemType getMemType() { return isOut_ ? MemType.IO_WRITE : MemType.IO_READ; }
	MemSpec getMemRef()  { MemSpec ret; return ret; }

	uint numDst() { return isOut_ ? 0 : 1; }
	uint numSrc() { return useDx_ ? 1 : 0; } //Ned, need AX as source

	ubyte getSrc(uint idx) { return RegNames.AX; }
	ubyte getDst(uint idx) { return RegNames.AX; }

	void execute(ArchState a)
	{
	}

	void disasm(ArchState a, out char[] str)
	{
		if( isOut_ )
		{
			str ~= "out ";

			if( useDx_ ) str ~= "DX, A";
			else
			{
				str ~= std.string.format("0x%02X, A", imm_);
			}

			if( opSz_ == OpSz.BYTE ) str ~= "L";
			else                     str ~= "X";
		}
		else
		{
			str ~= "in  A";

			if( opSz_ == OpSz.BYTE ) str ~= "L, ";
			else                     str ~= "X, ";

			if( useDx_ ) str ~= "DX";
			else         str ~= "Ib";
		}
	}
}

Inst86 ioFun(Prefixes *p, ubyte op, ArchState a)
{
	IoOp ret = new IoOp;
	ret.init(p, op, a);

	return ret;
}

