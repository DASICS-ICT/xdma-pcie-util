# 根目录Makefile
BUILD_DIR := ./build
XDMA_KO_PATH ?= ./xdma-ko/xdma_6.12.24.ko
DOWNLOAD_PATH ?= ./remote
BOOTROM_PATH ?= $(DOWNLOAD_PATH)/bootrom.bin
WORKLOAD_PATH ?= $(DOWNLOAD_PATH)/RV_BOOT.bin
BITSTREAM_PATH ?= $(DOWNLOAD_PATH)/system.bit

ONBOARD_OPTIONS ?= "--bypass" # 默认使用bypass选项
BOARD ?= vcu128
REMOTE_SW_DIR ?= nanhu-g/ready_for_download/proto_$(BOARD)
REMOTE_HW_DIR ?= work_farm/hw_plat/target_nanhu-g_proto_$(BOARD)

ifeq ($(BOARD),vcu128)
    FPGA_DEVICE_TYPE := xcvu37p_0
else ifeq ($(BOARD),s2c_vu19p)
    FPGA_DEVICE_TYPE := xcvu19p_0
else ifeq ($(BOARD),vcu1525)
    FPGA_DEVICE_TYPE := xcvu9p_0
else
    FPGA_DEVICE_TYPE := unset
endif

DEVICE_NUM ?= 01:00.0

USER ?= $(shell whoami)
EDA_HOST ?= unset
PATH_TO_NEXST ?= unset

.PHONY: all build_tools clean_tools list_devices program_fpga rescan_pci load_driver load_and_run load_and_run_rstsoc init_usergroup fetch_remote_sw fetch_remote_hw fetch_remote

all: build_tools

build_tools:
	$(MAKE) -C src

clean_tools:
	$(MAKE) -C src clean

list_devices:
	vivado -mode batch \
		-source ./scripts/program_fpga.tcl -notrace \
		-tclargs list_devices 

program_fpga:
ifneq ($(FPGA_DEVICE_TYPE),unset)
	vivado -mode batch \
		-source ./scripts/program_fpga.tcl -notrace \
		-tclargs $(FPGA_DEVICE_TYPE) $(BITSTREAM_PATH)
else
	$(error BOARD is not supported.)
endif
rescan_pci:
	sudo ./scripts/rescan_pci.sh $(DEVICE_NUM)

load_driver:
	sudo insmod $(XDMA_KO_PATH)

# 支持选项参数，默认无选项，用户可通过make load_and_run OPTIONS="--bypass --rstsoc --minicom"指定
load_and_run:
	./scripts/load_and_run.sh $(ONBOARD_OPTIONS) xdma0 $(BOOTROM_PATH) $(WORKLOAD_PATH)

init_usergroup:
	sudo ./scripts/init_xdma_usergroup.sh
	sudo usermod -aG xdma $(USER)
	@echo "Please log out and log back in for group changes to take effect, or run 'newgrp xdma'"

# 从EDA服务器获取软件文件
fetch_remote_sw:
ifneq ($(EDA_HOST),unset)
ifneq ($(PATH_TO_NEXST),unset)
	@echo "Fetching software files from EDA server..."
	bash -c "scp ${USER}@${EDA_HOST}:${PATH_TO_NEXST}/${REMOTE_SW_DIR}/{bootrom.bin,RV_BOOT.bin} $(DOWNLOAD_PATH)"
	@echo "Software files successfully fetched to $(DOWNLOAD_PATH)"
else
	$(error PATH_TO_NEXST is not set. Please specify path to Nexst build directory.)
endif
else
	$(error EDA_HOST is not set. Please specify EDA server hostname/IP.)
endif

# 从EDA服务器获取硬件文件
fetch_remote_hw:
ifneq ($(EDA_HOST),unset)
ifneq ($(PATH_TO_NEXST),unset)
	@echo "Fetching hardware files from EDA server..."
	bash -c "scp ${USER}@${EDA_HOST}:${PATH_TO_NEXST}/${REMOTE_HW_DIR}/{debug_nets.ltx,system.bit,system.hdf} $(DOWNLOAD_PATH)"
	@echo "Hardware files successfully fetched to $(DOWNLOAD_PATH)"
else
	$(error PATH_TO_NEXST is not set. Please specify path to Nexst build directory.)
endif
else
	$(error EDA_HOST is not set. Please specify EDA server hostname/IP.)
endif

# 从EDA服务器获取所有文件
fetch_remote: fetch_remote_sw fetch_remote_hw
