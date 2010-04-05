/// structures for handling x86 architectural state
module archstate;

/// descriptive names for gp registers
enum RegNames
{
	AX, CX, DX, BX,
	SP, BP, SI, DI,
	R8, R9, R10, R11,
	R12, R13, R14, R15
}

/// byte wide registers
enum RegBytes
{
	AL, CL, DL, BL,
	AH, CH, DH, BH
}

/// segment register names
enum SegReg
{
	ES, CS, SS, DS,
	FS, GS, HS, none
}

/**
 decode the modrm byte into its fields
	16 bit
		RM (mod 0,1,2)
		0 [BX+SI]
		1 [BX+DI]
		2 [BP+SI]
		3 [BP+DI]
		4 [SI]
		5 [DI]
		6 [imm16] (mod 0) / [BP] + imm (mod 1,2)
		7 [BX]
----------------------------------------------
	32 bit
		RM (mod 0,1,2)
		0..3,6,7 [reg]
		4 SIB (SP)
		5 [imm32] (mod 0) / [BP] + imm (mod 1,2)
 */
struct ByteModRM
{
	ubyte all;

	ubyte rm()
	{
		return all & 7;
	}

	ubyte reg()
	{
		return (all >> 3) & 7;
	}

	ubyte mod()
	{
		return (all >> 6) & 3;
	}

	bool hasMem()
	{
		return mod() != 3;
	}

	bool hasSib()
	{
		return hasMem() && rm() == 4;
	}
}

/// Scale Index Base
struct Sib
{
	ubyte all;

	ubyte scale()
	{
		return (all >> 6) & 3;
	}

	ubyte idx()
	{
		return (all >> 3) & 7;
	}

	ubyte base()
	{
		return all & 7;
	}
}

/// one register
union Reg86
{
	ulong rx;
	uint  ex;
	ushort x;

	struct Low
	{
		ubyte l;
		ubyte h;
	}
	Low _;
}

/// RFLAGS
struct Flags86
{
	uint all = 2;

	bool CF() { return (all & 1) != 0; }
	void CF(bool b) { all |= b ? 1 : 0; }
}

struct Prefixes
{
	bool   lock;
	bool   repne;
	bool   repe;
	SegReg seg = SegReg.none;
	bool   wordOver;
	bool   awordOver;
}

/// specify memory reference
struct MemSpec
{
	ulong     imm;
	ByteModRM mrm;
	Sib       sib;
	ubyte     rex;

	ubyte     seg = SegReg.DS;
	bool      lock;
	bool      wordOver;
	bool      awordOver;
}

interface ArchState
{
	ubyte * getByteReg (ubyte regspec);
	ushort* getWordReg (ubyte regspec);
	ulong * getQWordReg(ubyte regspec);

	ubyte * getByteMem (MemSpec* memspec);
	ushort* getWordMem (MemSpec* memspec);
	ulong * getQWordMem(MemSpec* memspec);

	ubyte  getNextIByte(); /// advance IP
	ubyte peekNextIByte(); /// do not
}

