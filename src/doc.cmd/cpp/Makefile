## Makefile — doc_cmd (C++)
CXX     = g++
CXXFLAGS = -O2 -Wall -Wextra -std=c++17
TARGET  = doc_cmd
ifeq ($(OS),Windows_NT)
    TARGET := doc_cmd.exe
endif

all: $(TARGET)

$(TARGET): doc_cmd.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	rm -f doc_cmd doc_cmd.exe

.PHONY: all clean
