# remove built-in rules
.SUFFIXES:

# what are we building
ifndef _ARCH
	_ARCH := $(shell uname)
	export _ARCH
endif

# and where
OBJDIR := ../_$(_ARCH)

# retrieve the make command line (e.g. make run)
MAKETARGET = $(MAKE) --no-print-directory -C $@ -f $(CURDIR)/Makefile \
    SRCDIR=$(CURDIR) $(MAKECMDGOALS)

# get us over to the object directory
.PHONY: $(OBJDIR)

$(OBJDIR):
	+@[ -d $@ ] || mkdir -p $@
	+@[ -d $@/insts ] || mkdir -p $@/insts
	+@$(MAKETARGET)

# prevent make from building makefiles
Makefile : ;
%.mk :: ;

# match everything and halt (depends on objdir)
% :: $(OBJDIR) ;

# provide for cleanup
.PHONY: clean
clean:
	rm -rf $(OBJDIR)

