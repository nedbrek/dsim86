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
	ulong ip_;

	ubyte[] mem_;

public:
	void init(Parms *p)
	{
		mem_ = new ubyte[p.memsz];
	}

	void loadImage(ubyte[] img, ulong startAddr)
	in
	{
		assert( mem_ && startAddr + img.length < mem_.length );
	}
	body
	{
		mem_[startAddr..startAddr+img.length] = img;
	}

	void setIP(ulong ip)
	{
		ip_ = ip;
	}

	void printNextIByte()
	{
		writefln("%x", ip_, ':', "%x", mem_[ip_]);
	}
}

