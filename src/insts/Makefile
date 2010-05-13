#--- Begin boilerplate
ifeq (,$(findstring _,$(CURDIR)))
include target.mk
else
VPATH = $(SRCDIR)

#--- End boilerplate

#--- Normal make stuff here!
.PHONY: insts

CFLAGS := -I$(SRCDIR)/.. -I$(SRCDIR) -Wall -g
LFLAGS := -g
OBJS := alu.o flagop.o io.o jump.o mov.o prefix.o segop.o strop.o

insts: $(OBJS)

-include Depend.Make

%.o : %.d
	@gdc -c $(CFLAGS) $<

#--- Begin boilerplate
endif

