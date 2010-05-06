module segop;

import archstate;
import inst;
import operand;
import std.string;

class MovSeg : Inst86
{
protected:
	Operand val_;
	ubyte   seg_;
	bool    isLoad_;

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		isLoad_ = (op & 2) != 0;

		ByteModRM mrm;
		mrm.all = a.getNextIByte();

		seg_ = mrm.reg;
		val_ = decodeMRM(a, mrm, OpSz.WORD, OpMode.MD16);
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef()  { MemSpec ret; return ret; }

	uint numDst() { return 1; }
	uint numSrc() { return 1; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= "mov ";
		if( isLoad_ )
			str ~= std.string.format("S%d, ", seg_);

		val_.disasm(str);

		if( !isLoad_ )
			str ~= std.string.format(", S%d", seg_);
	}
}

Inst86 segF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new MovSeg;
	ret.init(p, op, a);

	return ret;
}

