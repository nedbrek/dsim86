module segop;

import archstate;
import inst;
import operand;
import std.string;

static string[] seg_names = [
	"ES",
	"CS",
	"SS",
	"DS",
	"FS",
	"GS"
];

class MovSeg : Inst86
{
protected:
	Operand     val_;
	SegReg.Name seg_;
	bool        isLoad_;

public:
	void init(Prefixes *p, ubyte op, ArchState a)
	{
		isLoad_ = (op & 2) != 0;

		ByteModRM mrm;
		mrm.all = a.getNextIByte();

		seg_ = cast(SegReg.Name)(mrm.reg);
		val_ = decodeMRM(a, mrm, OpSz.WORD, OpMode.MD16);
	}

	MemType getMemType() { return MemType.NONE; }
	MemSpec getMemRef()  { MemSpec ret; return ret; }

	uint numDst() { return 1; }
	uint numSrc() { return 1; }

	ubyte getSrc(uint idx) { return 0; }
	ubyte getDst(uint idx) { return 0; }

	void execute(ArchState a)
	{
		SegReg *seg = a.getSegReg(seg_);
		if( isLoad_ )
			seg.val_ = cast(ushort)(val_.read(a));
		else
			val_.write(a, seg.val_);
	}

	void disasm(ArchState a, out char[] str)
	{
		str ~= "mov ";
		if( isLoad_ )
			str ~= std.string.format("%s, ", seg_names[seg_]);

		val_.disasm(str);

		if( !isLoad_ )
			str ~= std.string.format(", %s", seg_names[seg_]);
	}
}

Inst86 segF(Prefixes *p, ubyte op, ArchState a)
{
	auto ret = new MovSeg;
	ret.init(p, op, a);

	return ret;
}

