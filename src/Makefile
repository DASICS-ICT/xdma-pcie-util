O ?= $(shell pwd)
BUILD_DIR := ../build
TARGET := $(BUILD_DIR)/pcie-util
CXX := g++

objs-y += devmem.o
objs-y += sighandler.o
objs-y += uart.o
objs-y += main.o

objs-path-y = $(foreach obj,$(objs-y),$(O)/$(obj))

.PHONY: all load_workload rw_pcie_dram clean

all: $(TARGET) $(BUILD_DIR)/load_workload $(BUILD_DIR)/rw_pcie_dram

# 编译 load_workload 并输出到 $(BUILD_DIR)
$(BUILD_DIR)/load_workload: load_workload.c
	@mkdir -p $(BUILD_DIR)
	$(CXX) -o $@ $^

# 编译 rw_pcie_dram 并输出到 $(BUILD_DIR)
$(BUILD_DIR)/rw_pcie_dram: rw_pcie_dram.c
	@mkdir -p $(BUILD_DIR)
	$(CXX) -o $@ $^

clean:
	rm -rf $(objs-path-y) $(BUILD_DIR)

# 编译 .cc 文件为 .o 文件，放在 $(O) 目录下
$(O)/%.o: %.cc
	$(CXX) -c -o $@ $^

# 链接目标文件生成 $(TARGET)，放在 $(BUILD_DIR) 下
$(TARGET): $(objs-path-y)
	@mkdir -p $(BUILD_DIR)
	$(CXX) -o $@ $^