BEGIN {
	FS = ":"
}

{
	print "insts/" $1 ":" $2
}

