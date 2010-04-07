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
		ubyte * getByteReg (ubyte regspec) { return null; }
		ushort* getWordReg (ubyte regspec) { return null; }
		ulong * getQWordReg(ubyte regspec) { return null; }

		ulong* getOtherReg(RegSet s, ubyte idx)
		{
			switch( s )
			{
			case RegSet.IP   : return &ip_;
			case RegSet.FLAGS: return &flags_;
			case RegSet.CR   : return &cr_[idx];

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

