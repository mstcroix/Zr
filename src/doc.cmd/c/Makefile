## Makefile — doc_cmd (C)
CC      = gcc
CFLAGS  = -O2 -Wall -Wextra -std=c11
TARGET  = doc_cmd
ifeq ($(OS),Windows_NT)
    TARGET := doc_cmd.exe
endif

all: $(TARGET)

$(TARGET): doc_cmd.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f doc_cmd doc_cmd.exe

.PHONY: all clean
