/// structures for handling x86 architectural state
module archstate;

enum CC
{
	O, NO,  C, NC, Z, NZ, BE, A,
	S, NS, PE, PO, L, NL, LE, G,
	NONE
}

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
	AH, CH, DH, BH, // no REX
	SPL, BPL, SIL, DIL, // REX = 0
	R8L, R9L, R10L, R11L, // REX = 1
	R12L, R13L, R14L, R15L
}

enum OpSz
{
	BYTE, WORD, DWORD, QWORD, OWORD
}

/// segment register names
struct SegReg
{
	enum Name : ubyte
	{
		ES, CS, SS, DS,
		FS, GS, HS, none
	}

	ushort val_;
	uint   base_;
	uint   limit_;
}

enum RegSet
{
	GP,
	FLAGS,
	IP,
	SEG,
	X87,
	SSE,
	CR,
	DR,
	MSR,
	CPUID,
	RESTART_IP
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
		return cast(ubyte)(all & 7);
	}

	ubyte reg()
	{
		return cast(ubyte)((all >> 3) & 7);
	}

	ubyte mod()
	{
		return cast(ubyte)((all >> 6) & 3);
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
		return cast(ubyte)((all >> 6) & 3);
	}

	ubyte idx()
	{
		return cast(ubyte)((all >> 3) & 7);
	}

	ubyte base()
	{
		return cast(ubyte)(all & 7);
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

struct Rex
{
	ubyte all;

	bool B() { return (all & 1) != 0; }
	bool X() { return (all & 2) != 0; }
	bool R() { return (all & 4) != 0; }
	bool W() { return (all & 8) != 0; }
}

enum OpMode
{
	MD16,
	MD32,
	MD64
}

struct Prefixes
{
	Rex    rex;
	bool   lock;
	bool   repne;
	bool   repe;
	SegReg.Name seg = SegReg.Name.none;
	bool   wordOver;
	bool   awordOver;
}

interface Operand
{
   ulong read (ArchState a);
   void  write(ArchState a, ulong v);

   void disasm(inout char[] str);
}

/// specify memory reference
struct MemSpec
{
	Operand   base;
	Operand   index;
	ulong     imm;
	ubyte     scale = 1;

	ubyte     seg = SegReg.Name.DS;
	bool      lock;
}

interface ArchState
{
	ubyte * getByteReg (ubyte regspec);
	ushort* getWordReg (ubyte regspec);
	ulong * getQWordReg(ubyte regspec);

	SegReg* getSegReg(SegReg.Name idx);

	ulong* getOtherReg(RegSet s, uint idx);

	ubyte * getByteMem (MemSpec* memspec);
	ushort* getWordMem (MemSpec* memspec);
	uint  * getDWordMem(MemSpec* memspec);
	ulong * getQWordMem(MemSpec* memspec);

	ubyte  getNextIByte(); /// advance IP
	ubyte peekNextIByte(); /// do not
}

ushort getIword(ArchState a)
{
	ushort ret = a.getNextIByte();

	ret |= a.getNextIByte() << 8;

	return ret;
}

ulong signEx(ulong v, OpSz startSz, OpSz endSz)
{
	ulong ret = v;
	ulong mask = 0xffff_ffff_ffff_ffff;

	bool signBitSet = false;

	switch( startSz )
	{
	case OpSz.BYTE:
		signBitSet = (v & 128) != 0;
		mask &= ~0xff;
		break;

	default:
	}

	if( signBitSet )
	{
		switch( endSz )
		{
		case OpSz.WORD:
			mask &= 0xffff;
			break;

		case OpSz.QWORD:
		default:
		}
		ret |= mask;
	}

	return ret;
}

void makeFlags(ulong res, ArchState a)
{
	ulong *flagP = a.getOtherReg(RegSet.FLAGS, 0);

	// zero
	if( res == 0 )
		*flagP |= 0x20;
	else
		*flagP &= ~0x20;

	// carry
	if( res & 0x10000 )
		*flagP |= 0x1;
	else
		*flagP &= ~0x1;
}

bool checkCond(CC cond, ArchState a)
{
	ulong flags = *a.getOtherReg(RegSet.FLAGS, 0);
	switch( cond )
	{
	case CC.C : return  (flags & 0x01) != 0;
	case CC.NC: return  (flags & 0x01) == 0;
	case CC.Z : return  (flags & 0x20) != 0;
	case CC.NZ: return  (flags & 0x20) == 0;
	case CC.BE: return  (flags & 0x21) != 0;
	case CC.A : return  (flags & 0x21) == 0;

	default:
	}
	return false;
}

ulong formEA(ArchState a, in MemSpec *mem)
{
	ulong addr = 0;
	if( mem.index )
	{
		addr = mem.index.read(a);
		addr *= mem.scale;
	}

	addr += mem.imm;

	if( mem.base )
	{
		addr += mem.base.read(a);
	}

	return addr;
}

