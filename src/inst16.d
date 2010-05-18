module inst16;

import archstate;
import inst;
import insts.alu;
import insts.call;
import insts.flagop;
import insts.io;
import insts.jump;
import insts.mov;
import insts.prefix;
import insts.segop;
import insts.stack;
import insts.strop;
import std.stdio;

class InstFact
{
protected:
	alias Inst86 function(Prefixes *p, ubyte op, ArchState a) InstFun;

	InstFun[ubyte] decoder_;

public:
	this()
	{
		for(ubyte i = 0; i < 0x3f; ++i)
		{
			if( (i & 6) != 6 )
				decoder_[i] = &aluFun;
		}
		// 6,7 0..3f
		// 0x40..0x4f

		for(ubyte i = 0x50; i < 0x5f; ++i)
		{
			decoder_[i] = &stackF;
		}

		// 0x60..0x65

		decoder_[0x66] = &prefixF;
		decoder_[0x67] = &prefixF;

		//0x68
		//0x69
		//0x6a
		//0x6b

		decoder_[0x6c] = &strF;
		decoder_[0x6d] = &strF;
		decoder_[0x6e] = &strF;
		decoder_[0x6f] = &strF;

		for(ubyte i = 0x70; i < 0x7f; ++i)
		{
			decoder_[i] = &jmpI;
		}

		decoder_[0x80] = &aluFun;
		decoder_[0x81] = &aluFun;
		//0x82 rsvd
		decoder_[0x83] = &aluFun;

		// 0x84..0x87

		for(ubyte i = 0x88; i < 0x8b; ++i)
		{
			decoder_[i] = &movF;
		}

		// 0x8b

		decoder_[0x8c] = &segF;
		decoder_[0x8e] = &segF;

		decoder_[0x8d] = &leaF;

		// 0x8f..0xa3

		for(ubyte i = 0xa4; i <= 0xaf; ++i)
		{
			if( i != 0xa8 && i != 0xa9 )
				decoder_[i] = &strF;
		}

		// 0xa8,a9

		for(ubyte i = 0xb0; i <= 0xbf; ++i)
		{
			decoder_[i] = &movF;
		}

		// 0xc0..c2

		decoder_[0xc3] = &retOpF;

		// 0xc4..df

		// 0xe0..e3

		decoder_[0xe4] = &ioFun;
		decoder_[0xe5] = &ioFun;
		decoder_[0xe6] = &ioFun;
		decoder_[0xe7] = &ioFun;
		//e8,e9,ea,eb (below)
		decoder_[0xec] = &ioFun;
		decoder_[0xed] = &ioFun;
		decoder_[0xee] = &ioFun;
		decoder_[0xef] = &ioFun;

		decoder_[0xe8] = &callRelF;

		decoder_[0xe9] = &jmpI;
		decoder_[0xeb] = &jmpI;

		decoder_[0xea] = &jmpF;

		decoder_[0xf0] = &prefixF;
		// 0xf1
		decoder_[0xf2] = &prefixF;
		decoder_[0xf3] = &prefixF;
		// 0xf4

		decoder_[0xf5] = &flagF;
		decoder_[0xf8] = &flagF;
		decoder_[0xf9] = &flagF;
		decoder_[0xfa] = &flagF;
		decoder_[0xfb] = &flagF;
		decoder_[0xfc] = &flagF;
		decoder_[0xfd] = &flagF;

		// 0xf6..f7
		// 0xfe,ff
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

