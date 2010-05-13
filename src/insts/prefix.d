module prefix;

import archstate;
import inst;

Inst86 prefixF(Prefixes *p, ubyte op, ArchState a)
{
	switch( op )
	{
	case 0x66: p.wordOver  = true; break;
	case 0x67: p.awordOver = true; break;
	case 0xf0: p.lock      = true; break;
	case 0xf2: p.repne     = true; break;
	case 0xf3: p.repe      = true; break;

	default:
	}
	return null;
}

