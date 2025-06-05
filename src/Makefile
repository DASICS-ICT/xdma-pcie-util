O ?= $(shell pwd)
TARGET := pcie-util
CXX := g++

objs-y += devmem.o
objs-y += sighandler.o
objs-y += uart.o
objs-y += main.o

objs-path-y = $(foreach obj,$(objs-y),$(O)/$(obj))

.PHONY: all load_workload clean

all: $(TARGET) load_workload

load_workload: 
	gcc -o load_workload load_workload.c

clean:
	rm -f $(objs-path-y) $(TARGET)
	rm load_workload

$(O)/%.o: %.cc
	$(CXX) -c -o $@ $^

$(TARGET): $(objs-path-y)
	$(CXX) -o $@ $^
