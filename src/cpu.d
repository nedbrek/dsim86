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
protected:
	Reg86 gp_[16];
	ulong flags_;
	//Ned x87
	//Ned sse
	ulong cr_[16];
	ulong dr_[16];

	uint[uint] msr_;
	//Ned cpuid

	ulong ip_;

	ubyte[] mem_;

	class ArchStateAdapt : ArchState
	{
		ubyte* getByteReg(ubyte regspec)
		{
			// first for low regs
			if(regspec <= BL )
				return &gp_[regspec]._.l;

			// high regs
			if( AH <= regspec && regspec <= BH )
				return &gp_[regspec-AH]._.h;

			// remain low regs
			return &gp_[regspec-AH]._.l;
		}

		ushort* getWordReg(ubyte regspec)
		{
			return &gp_[regspec].x;
		}

		ulong* getQWordReg(ubyte regspec)
		{
			return &gp_[regspec].rx;
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
			ubyte ret = mem_[cast(uint)ip_];
			++ip_;

			return ret;
		}

		/// do not
		ubyte peekNextIByte()
		{
			return mem_[cast(uint)ip_];
		}
	}

	ArchStateAdapt aa_;

public:
	this()
	{
		flags_ = 2;

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

	void setIP(ulong ip)
	{
		ip_ = ip;
	}

	void printNextIByte()
	{
		writefln("%x", ip_, ':', "%x", mem_[cast(uint)ip_]);
	}
}

