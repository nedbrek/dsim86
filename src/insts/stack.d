module stack;

import archstate;
import inst;
import operand;

class StackOp : Inst86
{
protected:
	Operand op_;
	bool    isPop_;

public:
	void init(in Prefixes *p, ubyte op, ArchState a)
	{
		if( 0x06 <= op && op <= 0x1f )
		{
			// push/pop seg
			op_ = new RegOp(RegSet.SEG, cast(ubyte)((op >> 3) & 3), OpSz.WORD);
			isPop_ = (op & 1) != 0;
		}
		else if( 0x50 <= op && op <= 0x5f )
		{
			// push/pop +r
			op_ = new RegOp(RegSet.GP, cast(ubyte)(op & 7), OpSz.WORD);
			isPop_ = (op & 8) != 0;
		}
	}

	void initFF(in Prefixes *p, ByteModRM mrm, ArchState a)
	{
		op_ = decodeMRM(a, mrm, OpSz.WORD, OpMode.MD16);
		isPop_ = false;
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef () { MemSpec ret; return ret; }

	uint numDst() { return 1; }
	uint numSrc() { return 0; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		if( isPop_ )
			op_.write(a, pop(a, OpSz.WORD));
		else
			push(a, op_.read(a));
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= isPop_ ? "pop  " : "push ";
		op_.disasm(str);
	}
}

Inst86 stackF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new StackOp;
	ret.init(p, op, a);

	return ret;
}

