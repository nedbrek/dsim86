module flagop;

import archstate;
import inst;
import std.string;

class FlagOp : Inst86
{
	ubyte op_;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		op_ = op;
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
		// check for complement carry
		if (op_ == 0xf5)
		{
			str ~= "cmc";
			return;
		}

		// clear/set
		if (op_ & 1)
			str ~= "st";
		else
			str ~= "cl";

		const char[] flag_name = ['c', 'i', 'd'];
		str ~= flag_name[(op_ >> 1) & 3];
	}
}

Inst86 flagF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new FlagOp;
	ret.init(p, op, a);

	return ret;
}

