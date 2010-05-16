module strop;

import archstate;
import inst;
import operand;

private:
alias void function(ArchState a, OpSz sz) StrFun;

void ins(ArchState a, OpSz sz)
{
}

void outs(ArchState a, OpSz sz)
{
}

void movs(ArchState a, OpSz sz)
{
}

void cmps(ArchState a, OpSz sz)
{
}

void stos(ArchState a, OpSz sz)
{
	ushort *di = a.getWordReg(RegNames.DI);

	MemSpec mem;
	mem.seg = SegReg.Name.ES;
	mem.base = new RegOp(RegSet.GP, RegNames.DI, OpSz.WORD);

	switch( sz )
	{
	case OpSz.BYTE:
		// store AL to ES:DI
		*a.getByteMem(&mem) = *a.getByteReg(RegBytes.AL);

		// incr DI
		(*di)++;
		break;

	case OpSz.WORD:
		// store AX to ES:DI
		*a.getWordMem(&mem) = *a.getWordReg(RegNames.AX);

		// incr DI
		(*di) += 2;
		break;

	default:
	}
}

void lods(ArchState a, OpSz sz)
{
}

void scas(ArchState a, OpSz sz)
{
}

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
	static StrFun fun[7] = [
		&ins, &outs, &movs, &cmps, &stos, &lods, &scas
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
			sz_ = OpSz.WORD;
		else
			sz_ = OpSz.BYTE;

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
		fun[o_](a, sz_);

		if( rep_ )
		{
			ushort *cx = a.getWordReg(RegNames.CX);
			--(*cx);
			if( *cx != 0 )
			{
				*a.getOtherReg(RegSet.IP, 0) =
				   *a.getOtherReg(RegSet.RESTART_IP, 0);
			}
		}
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

public:
Inst86 strF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new StrOp;
	ret.init(p, op, a);

	return ret;
}

