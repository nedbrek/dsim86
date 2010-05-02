module operand;

import archstate;
import std.string;

interface Operand
{
   ulong read (ArchState a);
   void  write(ArchState a, ulong v);

	void disasm(inout char[] str);
}

class ImmOp : Operand
{
	ulong i_;

public:
	this(ulong i = 0)
	{
		i_ = i;
	}

	ulong read(ArchState a) { return i_; }
	void  write(ArchState a, ulong v) {}

	void disasm(inout char[] str)
	{
		str ~= "0x";
		str ~= std.string.toString(i_, 16u);
	}
}

class RegOp : Operand
{
	RegSet set_;
	ubyte  reg_;
	OpSz   sz_;

	static char[] byteRegs[] = [
		"AL", "CL", "DL", "BL",
		"AH", "CH", "DH", "BH",
		"SPL", "BPL", "SIL", "DIL",
		"R8L", "R9L", "R10L", "R11L",
		"R12L", "R13L", "R14L", "R15L"
	];
	static char[] wordRegs[] = [
		"AX", "CX", "DX", "BX",
		"SP", "BP", "SI", "DI"
	];

public:
	this(RegSet set, ubyte idx, OpSz sz)
	{
		set_ = set;
		reg_ = idx;
		sz_  = sz;
	}

	ulong read(ArchState a)
	{
		if( set_ != RegSet.GP )
		{
			if( set_ == RegSet.SEG )
				return a.getSegReg(cast(SegReg.Name)(reg_)).val_;

			return *(a.getOtherReg(set_, reg_));
		}
		//GP

		switch( sz_ )
		{
		case OpSz.BYTE:
			return *(a.getByteReg(reg_));

		case OpSz.WORD:
			return *(a.getWordReg(reg_));

		default:
			return *(a.getQWordReg(reg_));
		}
		return 0; // unreachable
	}

	void write(ArchState a, ulong v)
	{
	}

	void disasm(inout char[] str)
	{
		switch( sz_ )
		{
		case OpSz.BYTE:
			str ~= byteRegs[reg_];
			break;

		case OpSz.WORD:
			str ~= wordRegs[reg_];
			break;

		case OpSz.DWORD:
			str ~= "E";
			str ~= wordRegs[reg_];
			break;

		default:
		}
	}
}

class MemOp : Operand
{
	OpSz  sz_;
	RegOp base_;
	RegOp index_;
	ubyte scale_;
	ulong imm_;

public:
	this(OpSz sz, RegOp base, ulong imm = 0, RegOp idx = null, ubyte scale = 1)
	{
		sz_    = sz;
		base_  = base;
		index_ = idx;
		scale_ = scale;
		imm_   = imm;
	}

	ulong read(ArchState a)
	{
		ulong ret = 0;
		switch( sz_ )
		{
		case OpSz.BYTE:
			break;

		case OpSz.WORD:
			break;

		case OpSz.DWORD:
			break;

		case OpSz.QWORD:
			break;

		default:
		}
		return ret;
	}

	void write(ArchState a, ulong v)
	{
	}

	void disasm(inout char[] str)
	{
		str ~= "MEM";
	}
}

Operand decodeMRM(ArchState a, ByteModRM mrm, OpSz sz, OpMode mode)
{
	if( mode == OpMode.MD16 )
	{
		auto base = new RegOp(RegSet.GP, mrm.rm, OpSz.WORD);

		// no SIB
		switch( mrm.mod )
		{
		case 0:
			return new MemOp(sz, base);

		case 1:
			return new MemOp(sz, base);

		case 2:
			return new MemOp(sz, base);

		case 3:
			return new RegOp(RegSet.GP, mrm.rm, sz);

		default:
		}
	}
	return null;
}

