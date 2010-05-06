module flagop;

import archstate;
import inst;
import std.string;

class FlagOp : Inst86
{
	uint bit_;
	bool val_;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDst() { return 0; }
	uint    numSrc() { return 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= std.string.format("flags[%d] = %d", bit_, val_ ? 1:0);
	}
}

Inst86 flagF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new FlagOp;
	ret.init(p, op, a);

	return ret;
}

