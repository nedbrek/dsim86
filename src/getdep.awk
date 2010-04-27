#!/usr/bin/awk -f

/^import std\./ {
	next
}

/^import / {
	mod = $2
	sub(/;$/, ".d", mod)

	fn = FILENAME
	sub(/.d$/, ".o", fn)

	print fn ":" mod
}

