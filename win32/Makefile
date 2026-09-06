all: make_entry

_TARGET ?= $(shell uname -m)-pc-cygwin

CC 		:= $(_TARGET)-gcc
HOSTCC 	:= gcc

template.exe: entry.c
	$(CC) -o $@ $<

make_entry.exe: make_entry.c template.exe
	$(CC) -o $@ $<

make_entry: make_entry.c template.exe
	$(HOSTCC) -o $@ $<
