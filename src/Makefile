#--- Begin boilerplate
ifeq (,$(filter _%,$(notdir $(CURDIR)))) 
include target.mk
else
VPATH = $(SRCDIR)

#--- End boilerplate

#--- Normal make stuff here!
.PHONY: all run

CFLAGS := -I$(SRCDIR) -Wall -g
LFLAGS := -g
OBJS := main.o archstate.o cpu.o inst.o inst16.o instfact.o operand.o \
   insts/alu.o insts/io.o insts/jump.o insts/mov.o

all: ned86.exe

-include Depend.Make

run: ned86.exe
	@./ned86.exe < $(SRCDIR)/in.cmd

%.o : %.d
	@gdc -c $(CFLAGS) $<

ned86.exe: $(OBJS)
	@$(MAKE) -C $(SRCDIR)/insts
	@gdc $(LFLAGS) -o $@ $^

#--- Begin boilerplate
endif

