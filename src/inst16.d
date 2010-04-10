module inst16;

import archstate;
import inst;
import jump;
import std.stdio;

class InstFact
{
protected:
	alias Inst86 function(Prefixes *p, ubyte op, ArchState a) InstFun;

	InstFun[ubyte] decoder_;

public:
	this()
	{
		decoder_[0xeb] = &jmpI;
	}

	Inst86 makeInst(ArchState a)
	{
		Prefixes p;

		Inst86 ret = null;
		while( ret is null )
		{
			ubyte op = a.getNextIByte();

			InstFun *ifp = (op in decoder_);

			if( ifp is null )
			{
				writefln("Null in decoder for byte: ", "%x", op);
				return null;
			}
			else
			{
				ret = (*ifp)(&p, op, a);
			}
		}

		return ret;
	}
}

