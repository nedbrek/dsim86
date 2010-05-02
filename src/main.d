import archstate;
import cpu;
import instfact;
import std.file;
import std.stdio;

/** x86 simulator
 *
 */
void main(char[][] argv)
{
	writefln("Begin");

	ByteModRM modrm;
	modrm.all = 0xb1;
	writefln("Modrm ", modrm.mod, ' ', modrm.reg, ' ', modrm.rm);

	Reg86 r;
	r.rx = 0xdeadbeef_baadf00d;
	writefln("Reg: ", r.rx, ' ', r.ex, ' ', r.x, ' ', r._.h, ' ', r._.l);

	Flags86 flags;
	flags.CF = 1;
	writefln("Flags: ", flags.CF);

	Cpu c = new Cpu;
	cpu.Parms p;
	c.init(&p);

	void[] img = read("c:/ned/dev/gnu/bochs_cvs/bochs/bios/BIOS-bochs-latest");
	c.loadImage(cast(ubyte[])img, 0xe_0000);

	writefln("Start execute");

	for(uint ct = 0; ct < 18; ++ct)
	{
		c.printNextIByte();

		auto i = instFact(c.getAA());
		if( i is null )
		{
			writefln("Null decode");
		}
		else
		{
			char[] dstr;
			i.disasm(c.getAA(), dstr);
			writefln(" ", dstr);
			i.execute(c.getAA());
		}
	}

	c.printNextIByte();
	writefln();

	writefln("End");
}

