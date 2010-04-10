/// Instruction factory
module instfact;

import archstate;
import inst;
import inst16;
import std.stdio;

Inst86 instFact(ArchState a)
{
	ulong *cr0 = a.getOtherReg(RegSet.CR, 0);

	// check for protected mode flag
	if( (*cr0 & 1) == 0 )
	{
		auto i16f = new inst16.InstFact;
		return i16f.makeInst(a);
	}

	return null;
}

