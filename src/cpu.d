module cpu;

import archstate;
import std.stdio;

struct Parms
{
	uint memsz = 32 * 1024 * 1024;

	invariant()
	{
		assert( memsz != 0 );
	}
}

class Cpu
{
protected: // data
	Reg86 gp_[16];
	ulong flags_;
	//Ned x87
	//Ned sse
	SegReg segs_[6];
	ulong cr_[16];
	ulong dr_[16];

	ulong[uint] msr_; //Ned, could be uint, need other access
	//Ned cpuid

	ulong ip_ = 0xfff0; // power on value

	ubyte[] mem_;

protected: // methods
	ulong formIP_EA()
	{
		auto seg = segs_[SegReg.Name.CS];

		ulong ret = seg.base_;

		ret += seg.val_ << 4;
		ret += ip_;

		return ret;
	}

protected: // types
	class ArchStateAdapt : ArchState
	{
		ubyte* getByteReg(ubyte regspec)
		{
			// first for low regs
			if(regspec <= RegBytes.BL )
				return &gp_[regspec]._.l;

			// high regs
			if( RegBytes.AH <= regspec && regspec <= RegBytes.BH )
				return &gp_[regspec-RegBytes.AH]._.h;

			// remain low regs
			return &gp_[regspec-RegBytes.AH]._.l;
		}

		ushort* getWordReg(ubyte regspec)
		{
			return &gp_[regspec].x;
		}

		ulong* getQWordReg(ubyte regspec)
		{
			return &gp_[regspec].rx;
		}

		SegReg* getSegReg(SegReg.Name idx)
		{
			return &segs_[idx];
		}

		ulong* getOtherReg(RegSet s, uint idx)
		{
			switch( s )
			{
			case RegSet.FLAGS: return &flags_;
			case RegSet.IP   : return &ip_;

			case RegSet.CR   : return & cr_[idx];
			case RegSet.DR   : return & dr_[idx];
			case RegSet.MSR  : return &msr_[idx];

			default:;
			}
			return null;
		}

		ubyte * getByteMem (MemSpec* memspec) { return null; }
		ushort* getWordMem (MemSpec* memspec) { return null; }
		ulong * getQWordMem(MemSpec* memspec) { return null; }

		/// advance IP
		ubyte getNextIByte()
		{
			ubyte ret = peekNextIByte();
			++ip_;

			return ret;
		}

		/// do not
		ubyte peekNextIByte()
		{
			return mem_[cast(uint)formIP_EA()];
		}
	}

	ArchStateAdapt aa_;

public:
	this()
	{
		flags_ = 2;
		segs_[SegReg.Name.CS].val_ = 0xf000;

		aa_ = new ArchStateAdapt;
	}

	void init(Parms *p)
	{
		mem_ = new ubyte[p.memsz];
	}

	ArchState getAA() { return aa_; }

	void loadImage(ubyte[] img, ulong startAddr)
	in
	{
		assert( mem_ && startAddr + img.length < mem_.length );
	}
	body
	{
		mem_[cast(uint)startAddr..cast(uint)(startAddr+img.length)] = img;
	}

	/// intended for testing
	void setIP(ulong ip)
	{
		ip_ = ip;
	}

	void printNextIByte()
	{
		writefln("%04x", segs_[SegReg.Name.CS].val_, ":", "%04x", ip_, ':',
		    "%x", mem_[cast(uint)formIP_EA()]);
	}
}

