module jump;

import archstate;
import inst;

class JmpI : Inst86
{
protected:
	enum CC
	{
		O, NO,  C, NC, Z, NZ, BE, A,
		S, NS, PE, PO, L, NL, LE, G,
		NONE
	}

	uint off_;
	CC   cond_ = CC.NONE;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		// jcc ib
		if( 0x70 <= op && op <= 0x7f )
		{
			off_ = a.getNextIByte();
			cond_ = cast(CC)(op - 0x70);

			return;
		}

		// jmp ib
		if( op == 0xeb )
		{
			off_ = a.getNextIByte();
		}
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDest() { return 0; }
	uint    numSrc () { return cond_ == CC.NONE ? 1 : 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
	}

	void disasm(ArchState a, out char[] str)
	{
		str.length = "jmp".length;
		str[] = "jmp";
	}
}

Inst86 jmpI(Prefixes *p, ubyte op, ArchState a)
{
	JmpI ret = new JmpI;
	ret.init(p, op, a);

	return ret;
}

