module jump;

import archstate;
import inst;
import std.string;

class JmpI : Inst86
{
protected:
	ulong off_;
	CC    cond_ = CC.NONE;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		// jcc ib
		if( 0x70 <= op && op <= 0x7f )
		{
			off_ = signEx(cast(ulong)a.getNextIByte(), OpSz.BYTE, OpSz.QWORD);
			cond_ = cast(CC)(op - 0x70);

			return;
		}

		// jmp ib
		if( op == 0xeb )
		{
			off_ = signEx(a.getNextIByte(), OpSz.BYTE, OpSz.QWORD);
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
		if( cond_ != CC.NONE )
		{
			if( !checkCond(cond_, a) )
				return;
		}

		ulong *ip = a.getOtherReg(RegSet.IP, 0);
		(*ip) += off_;
	}

	void disasm(ArchState a, out char[] str)
	{
		if( cond_ == CC.NONE )
			str ~= "jmp";
		else
			str ~= std.string.format("j-%x", cond_);

		str ~= std.string.format(" 0x%016x", off_);
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
		off_ = getIword(a);
		seg_ = getIword(a);
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
		str ~= "jmpf ";
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

