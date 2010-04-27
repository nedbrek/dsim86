module jump;

import archstate;
import inst;
import std.string;

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

	uint    numDst() { return 0; }
	uint    numSrc() { return cond_ == CC.NONE ? 1 : 0; }

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

class FarJmp : public Inst86
{
protected:
	uint   off_;
	ushort seg_;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		ubyte b = a.getNextIByte();
		off_ = b;

		b = a.getNextIByte();
		off_ |= b << 8;

		b = a.getNextIByte();
		seg_ = b;
		b = a.getNextIByte();
		seg_ |= b << 8;
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDst() { return 0; }
	uint    numSrc() { return 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		SegReg *s = a.getSegReg(SegReg.Name.CS);
		s.val_ = seg_;
		ulong *ip = a.getOtherReg(RegSet.IP, 0);
		*ip = off_;
	}

	void disasm(ArchState a, out char[] str)
	{
		str.length = "jmpf ".length;
		str[] = "jmpf ";
		str ~= std.string.toString(cast(ulong)seg_, 16u);
		str ~= ":";
		str ~= std.string.toString(cast(ulong)off_, 16u);
	}
}

Inst86 jmpF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new FarJmp;
	ret.init(p, op, a);

	return ret;
}

