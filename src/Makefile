#--- Begin boilerplate
ifeq (,$(filter _%,$(notdir $(CURDIR)))) 
include target.mk
else
VPATH = $(SRCDIR)

#--- End boilerplate

#--- Normal make stuff here!
.PHONY: all run

all: ned86.exe

run: ned86.exe
	@./ned86.exe

%.o : %.d
	@gdc -c $<

ned86.exe: main.o
	@gdc -o $@ $^

#--- Begin boilerplate
endif

