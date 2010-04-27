module alu;

import archstate;
import inst;

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
	}
}

public Inst86 aluFun(Prefixes *p, ubyte op, ArchState a)
{
	AluOp ret = new AluOp;
	ret.init(p, op, a);

	return ret;
}

