import archstate;
import cpu;
import std.stdio;

align(1) struct ExeHeader
{
  ushort signature; // == 0x5a4D
  ushort bytes_in_last_block; // if != 0, subtract from 512
  ushort blocks_in_file; // total number of 512 blocks (including last block)
  ushort num_relocs; // number of relocation entries
  ushort header_paragraphs; // * 16 for sizeof header
  ushort min_extra_paragraphs; // requested memory
  ushort max_extra_paragraphs; // maximum memory to allocate
  ushort ss; // stack segment
  ushort sp; // stack pointer
  ushort checksum; // checksum of file
  ushort ip; // instruction pointer
  ushort cs; // code segment (relative to start segment)
  ushort reloc_table_offset; // start of relocation entries
  ushort overlay_number; // for program use
};

struct ExeReloc
{
	ushort offset;
	ushort segment;
};

void dumpExe(string path)
{
	auto f = File(path);

	ExeHeader hdr;
	f.rawRead((&hdr)[0..1]);
	if (hdr.signature != 0x5a4d) // MZ (little endian)
	{
		writefln("Bad header signature: %x", hdr.signature);
		return;
	}

	uint total_bytes = hdr.blocks_in_file * 512;
	ushort bytes_in_last_block = hdr.bytes_in_last_block;
	if (bytes_in_last_block != 0)
	{
		// reduce total by shortfall in last block
		total_bytes -= 512 - bytes_in_last_block;
	}
	writefln("Total bytes: %d", total_bytes);
}

void loadExe(string path, Cpu cpu)
{
	auto f = File(path);

	ExeHeader hdr;
	f.rawRead((&hdr)[0..1]);
	if (hdr.signature != 0x5a4d) // MZ (little endian)
	{
		writefln("Bad header signature: %x", hdr.signature);
		return;
	}

	uint total_bytes = hdr.blocks_in_file * 512;
	ushort bytes_in_last_block = hdr.bytes_in_last_block;
	if (bytes_in_last_block != 0)
	{
		// reduce total by shortfall in last block
		total_bytes -= 512 - bytes_in_last_block;
	}
	ubyte[] hdr_remainder;
	hdr_remainder.length = hdr.header_paragraphs * 16 - ExeHeader.sizeof;
	f.rawRead(hdr_remainder);

	ubyte[] img;
	img.length = total_bytes;
	auto program = f.rawRead(img);
	writefln("Size: %d", program.length);
	// TODO move up, and handle relocations
	ulong start_addr = 0x0_0000;
	cpu.loadImage(img, start_addr);

	// load register values
	auto aa = cpu.getAA();
	aa.getSegReg(SegReg.Name.CS).val_ = hdr.cs;
	aa.getSegReg(SegReg.Name.SS).val_ = hdr.ss;
	*aa.getOtherReg(RegSet.IP, 0) = hdr.ip;
	*aa.getWordReg(RegNames.SP) = hdr.sp;
}

