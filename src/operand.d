module operand;

import archstate;

interface Operand
{
   ulong read (ArchState a);
   void  write(ArchState a, ulong v);
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
}

class RegOp : Operand
{
	RegSet set_;
	ubyte  reg_;
	OpSz   sz_;

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
}

