#--- Begin boilerplate
ifeq (,$(filter _%,$(notdir $(CURDIR)))) 
include target.mk
else
VPATH = $(SRCDIR)

#--- End boilerplate

#--- Normal make stuff here!
.PHONY: all run test

CFLAGS := -I$(SRCDIR) -Wall -g
LFLAGS := -g
OBJS := main.o archstate.o cpu.o inst.o inst16.o instfact.o operand.o \
   insts/alu.o insts/call.o insts/flagop.o insts/io.o insts/jump.o \
   insts/mov.o insts/prefix.o insts/segop.o insts/strop.o

all: ned86.exe

-include Depend.Make

run: ned86.exe
	@./ned86.exe

test: ned86.exe
	@./ned86.exe < $(SRCDIR)/in.cmd > $(SRCDIR)/test.out
	@cat $(SRCDIR)/eol.txt >> $(SRCDIR)/test.out
	@echo diff test.gold test.out
	@diff $(SRCDIR)/test.gold $(SRCDIR)/test.out

%.o : %.d
	@gdc -c $(CFLAGS) $<

ned86.exe: $(OBJS)
	@$(MAKE) -C $(SRCDIR)/insts
	@gdc $(LFLAGS) -o $@ $^

#--- Begin boilerplate
endif

