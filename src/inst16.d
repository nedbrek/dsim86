module inst16;

import archstate;
import inst;
import insts.alu;
import insts.flagop;
import insts.io;
import insts.jump;
import insts.mov;
import std.stdio;

class InstFact
{
protected:
	alias Inst86 function(Prefixes *p, ubyte op, ArchState a) InstFun;

	InstFun[ubyte] decoder_;

public:
	this()
	{
		for(ubyte i = 0; i < 0x4f; ++i)
		{
			if( (i & 6) != 6 )
				decoder_[i] = &aluFun;
		}

		for(ubyte i = 0x70; i < 0x7f; ++i)
		{
			decoder_[i] = &jmpI;
		}

		for(ubyte i = 0x88; i < 0x8b; ++i)
		{
			decoder_[i] = &movF;
		}

		for(ubyte i = 0xb0; i < 0xbf; ++i)
		{
			decoder_[i] = &movF;
		}

		decoder_[0xe4] = &ioFun;
		decoder_[0xe5] = &ioFun;
		decoder_[0xe6] = &ioFun;
		decoder_[0xe7] = &ioFun;
		decoder_[0xec] = &ioFun;
		decoder_[0xed] = &ioFun;
		decoder_[0xee] = &ioFun;
		decoder_[0xef] = &ioFun;

		decoder_[0xea] = &jmpF;
		decoder_[0xeb] = &jmpI;

		decoder_[0xf5] = &flagF;
		decoder_[0xf8] = &flagF;
		decoder_[0xf9] = &flagF;
		decoder_[0xfa] = &flagF;
		decoder_[0xfb] = &flagF;
		decoder_[0xfc] = &flagF;
		decoder_[0xfd] = &flagF;
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
				return null;
			}

			ret = (*ifp)(&p, op, a);
		}

		return ret;
	}
}

