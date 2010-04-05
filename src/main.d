import archstate;
import cpu;
import std.stdio;

/** x86 simulator
 *
 */
void main(char[][] argv)
{
	writefln("Begin");

	archstate.ByteModRM modrm;
	modrm.all = 0xb1;
	writefln("Modrm ", modrm.mod, ' ', modrm.reg, ' ', modrm.rm);

	Reg86 r;
	r.rx = 0xdeadbeef_baadf00d;
	writefln("Reg: ", r.rx, ' ', r.ex, ' ', r.x, ' ', r._.h, ' ', r._.l);

	Flags86 flags;
	flags.CF = 1;
	writefln("Flags: ", flags.CF);

	cpu.Cpu c = new cpu.Cpu;
	cpu.Parms p;
	c.init(&p);

	ubyte[] img;
	img.length = 2;
	img[0] = 0xeb;
	img[1] = 0x3c;
	c.loadImage(img, 0x7c00);

	c.setIP(0x7c00);
	c.printNextIByte();

	writefln("End");
}

