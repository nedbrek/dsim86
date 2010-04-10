import archstate;
import cpu;
import instfact;
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

	ubyte[] img;
	img.length = 3;
	img[0] = 0xeb;
	img[1] = 0x3c;
	img[2] = 0x90;
	c.loadImage(img, 0x7c00);

	c.setIP(0x7c00);
	c.printNextIByte();

	auto i = instFact(c.getAA());
	char[] dstr;
	i.disasm(c.getAA(), dstr);
	writefln("Disasm: ", dstr);

	c.printNextIByte();

	writefln("End");
}

