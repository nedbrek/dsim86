module operand;

import archstate;
import std.string;

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
		if( set_ != RegSet.GP )
		{
			if( set_ == RegSet.SEG )
				a.getSegReg(cast(SegReg.Name)(reg_)).val_ = cast(ushort)(v);

			*(a.getOtherReg(set_, reg_)) = v;
		}
		//GP

		switch( sz_ )
		{
		case OpSz.BYTE:
			*(a.getByteReg(reg_)) = cast(ubyte)(v);

		case OpSz.WORD:
			*(a.getWordReg(reg_)) = cast(ushort)(v);

		default:
			*(a.getQWordReg(reg_)) = v;
		}
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
		str ~= "[";

		bool hadReg = false;
		if( base_ )
		{
			base_.disasm(str);
			hadReg = true;
		}
		if( index_ )
		{
			if( hadReg )
				str ~= "+";

			index_.disasm(str);
			hadReg = true;
		}

		if( imm_ != 0 )
		{
			if( hadReg )
				str ~= "+";

			str ~= std.string.format("%04x]", imm_);
		}
		else
			str ~= "]";
	}
}

Operand decodeMRM(ArchState a, ByteModRM mrm, OpSz sz, OpMode mode)
{
	if( mode == OpMode.MD16 )
	{
		if( mrm.mod == 3 )
			return new RegOp(RegSet.GP, mrm.rm, sz);

		RegOp base;
		RegOp index;
		ulong imm;

		switch( mrm.rm )
		{
		case 0:
		case 1:
			base  = new RegOp(RegSet.GP, cast(ubyte)(mrm.rm+6), OpSz.WORD);
			index = new RegOp(RegSet.GP, 3,        OpSz.WORD);
			break;

		case 2:
		case 3:
			base  = new RegOp(RegSet.GP, cast(ubyte)(mrm.rm+4), OpSz.WORD);
			index = new RegOp(RegSet.GP, 5,        OpSz.WORD);
			break;

		case 4:
		case 5:
			base = new RegOp(RegSet.GP, cast(ubyte)(mrm.rm+2), OpSz.WORD);
			break;

		case 6:
			// BP needs offset or it is imm only
			if( mrm.mod == 0 )
				imm = getIword(a);
			else
				base = new RegOp(RegSet.GP, 5, OpSz.WORD);
			break;

		case 7:
			base = new RegOp(RegSet.GP, 3, OpSz.WORD);
			break;

		default:
		}

		// no SIB
		switch( mrm.mod )
		{
		case 1: // byte off
			imm = signEx(a.getNextIByte(), OpSz.BYTE, OpSz.WORD);
			break;

		case 2: // word off
			imm = getIword(a);
			break;

		case 0: // no imm
		case 3: // reg, above
		default:
		}
		return new MemOp(sz, base, imm, index);
	}
	return null;
}

