/// Instructions
module inst;

import archstate;

interface Inst86
{
	enum MemType
	{
		NONE,       /// reg-to-reg
		READ,       /// load or load-op
		WRITE,      /// store
		RMW,        /// load-op-store
		READ_MANY,  /// string read  (cmps)
		WRITE_MANY, /// string store (stos)
		RW_MANY     /// memcopy
	}
	MemType getMemType();

	MemSpec getMemRef();

	uint numDest(); /// 2 -> DX:AX *= reg
	uint numSrc (); /// not counting mem

	ubyte getSrc(uint idx);
	ubyte getDst(uint idx);

	void execute(ArchState a);
	void disasm (ArchState a, out char[] str);
}

