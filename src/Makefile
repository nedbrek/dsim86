all: ned86.exe

#--- Begin boilerplate
ifeq (,$(filter _%,$(notdir $(CURDIR)))) 
include target.mk
else
VPATH = $(SRCDIR)

#--- End boilerplate

#--- Normal make stuff here!
.PHONY: all run test view

DC := gdc
LINK := gdc
#CFLAGS := -I$(SRCDIR) -Wall -g
#CFLAGS := -I$(shell cygpath -m $(SRCDIR)) -w -g
CFLAGS := -I$(SRCDIR) -w -g
LFLAGS := -g
OBJS := main.obj archstate.obj cpu.obj dos.obj inst.obj inst16.obj instfact.obj operand.obj \
   insts/alu.obj insts/call.obj insts/flagop.obj insts/io.obj insts/jump.obj \
   insts/mov.obj insts/prefix.obj insts/segop.obj insts/stack.obj insts/strop.obj

-include $(SRCDIR)/Depend.Make
-include $(SRCDIR)/insts/Depend.Make

run: ned86.exe
	@./ned86.exe

view: test
	@tail -n15 $(SRCDIR)/test.out

test: ned86.exe
	@./ned86.exe < $(SRCDIR)/in.cmd > $(SRCDIR)/test.out
	@cat $(SRCDIR)/eol.txt >> $(SRCDIR)/test.out
	@echo diff test.gold test.out
	@diff $(SRCDIR)/test.gold $(SRCDIR)/test.out

#@$(DC) -c $(CFLAGS) -of$@ $(shell cygpath -m $<)
%.obj : %.d
	@$(DC) -c $(CFLAGS) -o$@ $<

ned86.exe: $(OBJS)
	@$(LINK) $(LFLAGS) -o$@ $^

#--- Begin boilerplate
endif

