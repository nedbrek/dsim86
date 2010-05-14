module call;

import archstate;
import inst;
import std.string;

class CallRel : Inst86
{
protected:
	ulong off_;
 
public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		off_ = getIword(a);
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDst() { return 0; }
	uint    numSrc() { return 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		ulong *ip = a.getOtherReg(RegSet.IP, 0);
		//push ip
		*ip += off_;
		*ip &= 0xffff;
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= "call ";
		str ~= std.string.toString(off_, 16u);
	}
}

Inst86 callRelF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new CallRel;
	ret.init(p, op, a);

	return ret;
}

