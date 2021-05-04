import archstate;
import inst;
import std.string;

class IntI : Inst86
{
protected:
	ubyte int_num_; // interrupt number
	bool check_of_ = false; // check overflow flag

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		if (op == 0xce)
		{
			check_of_ = true;
			int_num_ = 4;
		}
		else if (op == 0xcc)
		{
			int_num_ = 3;
		}
		else
		{
			int_num_ = a.getNextIByte();
		}
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDst() { return 0; }
	uint    numSrc() { return check_of_ ? 1 : 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		// TODO
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= "int";
		if (check_of_)
			str ~= "o";
		else
			str ~= std.string.format(" 0x%x", int_num_);
	}
}

class IRet : Inst86
{
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
		// TODO
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= "iret";
	}
}

Inst86 intOpF(Prefixes *p, ubyte op, ArchState a)
{
	if (op == 0xcf)
	{
		IRet ret = new IRet;
		ret.init(p, op, a);

		return ret;
	}
	IntI ret = new IntI;
	ret.init(p, op, a);

	return ret;
}

