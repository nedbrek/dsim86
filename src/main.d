import archstate;
import cpu;
import inst;
import instfact;
import std.conv;
import std.file;
import std.stdio;
import std.string;

void step(in Cpu c, inout Inst86 i, bool print)
{
	if( i is null )
	{
		writefln(" Null execute");
		return;
	}

	i.execute(c.getAA());

	if( print )
		c.printNextIByte();

	i = instFact(c.getAA());
	if( print && i !is null )
	{
		char[] dstr;
		i.disasm(c.getAA(), dstr);
		writefln(" ", dstr);
	}
}

/** x86 simulator
 *
 */
void main(char[][] argv)
{
	writefln("Begin");

	Cpu myCpu = new Cpu;
	cpu.Parms p;
	myCpu.init(&p);

	void[] img = read("c:/ned/dev/gnu/bochs_cvs/bochs/bios/BIOS-bochs-latest");
	myCpu.loadImage(cast(ubyte[])img, 0xe_0000);

	writefln("Start execute");
	char[] dstr;

	myCpu.printNextIByte();

	auto op = instFact(myCpu.getAA());
	if( op !is null )
	{
		op.disasm(myCpu.getAA(), dstr);
		writefln(" ", dstr);
	}

	char cmd = 's';

	while( 1 )
	{
		writef("-");
		char[] buf = readln();
		if( buf[0] != '\n' )
			cmd = buf[0];

		switch( cmd )
		{
		case 'n':
			ulong curIp = *myCpu.getAA().getOtherReg(RegSet.IP, 0);
			do
			{
				step(myCpu, op, false);
			} while( *myCpu.getAA().getOtherReg(RegSet.IP, 0) == curIp );

			myCpu.printRestartIByte();
			if( op !is null )
			{
				op.disasm(myCpu.getAA(), dstr);
				writefln(" ", dstr);
			}

			break;

		case 'q': return;

		case 'r':
			myCpu.printRegs(dstr);
			writefln("\n", dstr, "\n");
			break;

		case 's':
			int ct = 1;

			char[][] words = std.string.split(buf);
			if( words.length == 2 )
			{
				ct = std.conv.toInt(words[1]);
			}
			else if( words.length > 2 )
			{
				writefln("Usage: step [ct]");
			}

			for(int i = 0; i < ct; ++i)
				step(myCpu, op, true);

			break;

		default:
		}
	}

	writefln("End");
}

