import archstate;
import cpu;
import inst;
import instfact;
import std.conv;
import std.file;
import std.stdio;
import std.string;

void step(Cpu c, Inst86 i)
{
	if( i is null )
	{
		writefln(" Null execute");
		return;
	}

	i.execute(c.getAA());
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

	void[] img = read("/usr/local/ned/dev/gnu/bochs-code/bochs/bios/BIOS-bochs-latest");
	myCpu.loadImage(cast(ubyte[])img, 0xe_0000);

	writefln("Start execute");
	char[] dstr;

	myCpu.printNextIByte();

	auto op = instFact(myCpu.getAA());
	if( op !is null )
	{
		op.disasm(myCpu.getAA(), dstr);
		writefln(" %s", dstr);
	}

	char cmd = 's';

	while( 1 )
	{
		writef("-");
		string buf = readln();
		if( buf[0] != '\n' )
			cmd = buf[0];

		// remove trailing whitespace
		buf = strip(buf);

		switch( cmd )
		{
		case 'n':
			bool stepMore;
			ulong nxtIp = *myCpu.getAA().getOtherReg(RegSet.IP, 0);
			do
			{
				step(myCpu, op);
				stepMore = *myCpu.getAA().getOtherReg(RegSet.IP, 0) != nxtIp;

				op = instFact(myCpu.getAA());
			} while( stepMore );

			myCpu.printRestartIByte();
			if( op !is null )
			{
				op.disasm(myCpu.getAA(), dstr);
				writefln(" %s", dstr);
			}

			break;

		case 'q': return;

		case 'r':
			myCpu.printRegs(dstr);
			writefln("\n%s\n", dstr);
			break;

		case 's':
			if( buf == "sreg" )
			{
				myCpu.printSegs(dstr);
				writefln("\n%s\n", dstr);
				break;
			}

			int ct = 1;

			string[] words = std.string.split(buf);
			if( words.length == 2 )
			{
				ct = std.conv.to!int(words[1]);
			}
			else if( words.length > 2 )
			{
				writefln("Usage: step [ct]");
			}

			for(int i = 0; i < ct; ++i)
			{
				step(myCpu, op);

				myCpu.printNextIByte();

				op = instFact(myCpu.getAA());
				if( op !is null )
				{
					op.disasm(myCpu.getAA(), dstr);
					writefln(" %s", dstr);
				}
			}

			break;

		case 'x':
			string[] words = std.string.split(buf);

			ulong addr = std.conv.to!int(words[1]);
			if( buf != "xp" )
			{
				// virtual to phys trans
			}
			ubyte *val = myCpu.readMem(addr);
			writefln("%x:", addr, " %x", *cast(ushort*)(val));

			break;

		default:
		}
	}
}

