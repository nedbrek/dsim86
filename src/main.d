import archstate;
import cpu;
import dos;
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
void main(string[] argv)
{
	writefln("Begin %s", argv[0]);

	Cpu myCpu = new Cpu;
	cpu.Parms p;
	myCpu.init(&p);

	string path = "/usr/local/ned/dev/gnu/bochs-code/bochs/bios/BIOS-bochs-legacy";
	if (argv.length > 1)
		path = argv[1];

	string ext = std.path.extension(path);
	writefln("Ext: '%s'", ext);
	if (ext.toLower == ".exe")
	{
		//dos.dumpExe(path);
		dos.loadExe(path, myCpu);
	}
	else
	{
		ubyte[] img = cast(ubyte[])read(path);
		myCpu.loadImage(img, 0xf_0000);
	}

	writefln("Start execute %s", path);
	char[] dstr;

	myCpu.printNextIByte();

	auto op = instFact(myCpu.getAA());
	if( op !is null )
	{
		op.disasm(myCpu.getAA(), dstr);
		writefln("%s", dstr);
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
		case 'd':
			auto aa = myCpu.getAA();
			ulong orig_ip = *aa.getOtherReg(RegSet.IP, 0);
			ushort orig_cs = aa.getSegReg(SegReg.Name.CS).val_;

			int ct = 1;
			string[] words = std.string.split(buf);
			if( words.length == 2 )
			{
				ct = std.conv.to!int(words[1]);
			}
			else if( words.length > 2 )
			{
				writefln("Usage: %s [ct]", words[0]);
			}

			for (int i = 0; i < ct; ++i)
			{
				myCpu.printNextIByte();

				op = instFact(myCpu.getAA());
				if( op !is null )
				{
					op.disasm(myCpu.getAA(), dstr);
					writefln("%s", dstr);
				}
				else
				{
					writefln("(null)");
				}
			}

			 *aa.getOtherReg(RegSet.IP, 0) = orig_ip;
			 aa.getSegReg(SegReg.Name.CS).val_ = orig_cs;
			break;

		case 'n':
			bool stepMore;
			ulong nxtIp = *myCpu.getAA().getOtherReg(RegSet.IP, 0);
			const bool old_print = myCpu.printIBytes();
			myCpu.setPrintIBytes(false);
			do
			{
				step(myCpu, op);
				stepMore = *myCpu.getAA().getOtherReg(RegSet.IP, 0) != nxtIp;

				op = instFact(myCpu.getAA());
			} while( stepMore );

			myCpu.setPrintIBytes(old_print);
			myCpu.printRestartIByte();
			if( op !is null )
			{
				op.disasm(myCpu.getAA(), dstr);
				writefln("%s", dstr);
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
					writefln("%s", dstr);
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
			writefln("%x: %02x %02x", addr, val[0], val[1]);

			break;

		default:
		}
	}
}

