module strop;

import archstate;
import inst;

class StrOp : Inst86
{
	enum Op
	{
		INS, OUTS, MOVS, CMPS, STOS, LODS, SCAS
	}
	static char[4] names[7] = [
		"INS ", "OUTS", // io
		"MOVS", "CMPS", // mem to mem
		"STOS", "LODS", "SCAS" // reg to mem
	];

	Op   o_;
	OpSz sz_;
	bool rep_;
	bool eq_;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		rep_ = p.repe || p.repne;

		if( op & 1 )
			sz_ = OpSz.BYTE;
		else
			sz_ = OpSz.WORD;

		switch( op )
		{
		case 0x6c, 0x6d, 0x6e, 0x6f: // ops 0,1
			o_ = cast(Op)((op >> 1) - 54);
			break;

		case 0xa4, 0xa5, 0xa6, 0xa7: // ops 2,3
		  o_ = cast(Op)((op >> 1) - 80);
		  break;

		case 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf:
		  o_ = cast(Op)((op >> 1) - 81);
		  break;

		default:
		}
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint    numDst() { return 0; }
	uint    numSrc() { return 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
	}

	void disasm(ArchState a, out char[] str)
	{
		if( rep_ )
			str ~= "REP ";
		str ~= names[o_];
		if( sz_ == OpSz.BYTE )
			str ~= "B";
		else
			str ~= "W";
	}
}

Inst86 strF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new StrOp;
	ret.init(p, op, a);

	return ret;
}

