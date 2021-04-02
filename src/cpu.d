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
	ulong restartIp_;

	ubyte[] mem_;

protected: // methods
	ulong formIP_EA(ulong ip)
	{
		auto seg = segs_[SegReg.Name.CS];

		ulong ret = seg.base_;

		ret += seg.val_ << 4;
		ret += ip;

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
			case RegSet.RESTART_IP: return &restartIp_;

			case RegSet.CR   : return & cr_[idx];
			case RegSet.DR   : return & dr_[idx];
			case RegSet.MSR  : return &msr_[idx];

			default:;
			}
			return null;
		}

		ubyte * getByteMem (MemSpec* mem)
		{
			ulong addr = formEA(this, mem);
			addr &= 0xffff;

			SegReg *seg = getSegReg(cast(SegReg.Name)(mem.seg));
			addr += seg.val_ << 4;
			
			return &mem_[cast(uint)(addr)];
		}

		ushort* getWordMem (MemSpec* memspec)
		{ return cast(ushort*)getByteMem(memspec); }

		uint  * getDWordMem(MemSpec* memspec)
		{ return cast(uint*)getByteMem(memspec); }

		ulong * getQWordMem(MemSpec* memspec)
		{ return cast(ulong*)getByteMem(memspec); }

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
			return mem_[cast(uint)formIP_EA(ip_)];
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

	ubyte* readMem(ulong pa)
	{
		return &mem_[cast(uint)(pa)];
	}

	/// intended for testing
	void setIP(ulong ip)
	{
		segs_[SegReg.Name.CS].val_ = cast(ushort)(ip >> 16);
		ip_ = ip & 0xffff;
	}

	void printRestartIByte()
	{
		writef("%04x:%04x:%08x", segs_[SegReg.Name.CS].val_, restartIp_,
		    mem_[cast(uint)formIP_EA(restartIp_)]);
	}

	void printNextIByte()
	{
		writef("%04x:%04x:%02x", segs_[SegReg.Name.CS].val_, ip_,
		    mem_[cast(uint)formIP_EA(ip_)]);
	}

	void printSegs(out char[] ostr)
	{
		uint ct = 0;
		foreach(seg; segs_)
		{
			ostr ~= std.string.format("%04x ", seg.val_);
			++ct;
			if( ct == 4 )
			{
				ostr ~= "\n";
				ct = 0;
			}
		}
	}

	void printRegs(out char[] ostr)
	{
		uint ct = 0;
		foreach(r; gp_)
		{
			ostr ~= std.string.format("%016x ", r.rx);
			++ct;
			if( ct == 4 )
			{
				ostr ~= "\n";
				ct = 0;
			}
		}
		ostr ~= std.string.format("RFLAGS: %08x\n", flags_);
	}
}

