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

	Cpu c = new Cpu;
	cpu.Parms p;
	c.init(&p);

	void[] img = read("c:/ned/dev/gnu/bochs_cvs/bochs/bios/BIOS-bochs-latest");
	c.loadImage(cast(ubyte[])img, 0xe_0000);

	writefln("Start execute");
	char[] dstr;

	c.printNextIByte();

	auto i = instFact(c.getAA());
	if( i !is null )
	{
		i.disasm(c.getAA(), dstr);
		writefln(" ", dstr);
	}

	char cmd = 's';

	while( 1 )
	{
		char[] buf = readln();
		if( buf[0] != '\n' )
			cmd = buf[0];

		switch( cmd )
		{
		case 'q': return;

		case 'r':
			c.printRegs(dstr);
			writefln("\n", dstr, "\n");
			break;

		case 's':
			if( i is null )
			{
				writefln("Null decode");
				return;
			}

			i.execute(c.getAA());

			c.printNextIByte();

			i = instFact(c.getAA());
			if( i !is null )
			{
				i.disasm(c.getAA(), dstr);
				writefln(" ", dstr);
			}

			break;

		default:
		}
	}

	writefln("End");
}

