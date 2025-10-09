#!/bin/bash

usage() {
    cat <<EOF
Usage: $0 [--bypass] [--rstsoc] [--minicom] <xdmaN> <bootrom.bin> <fw_payload.bin>    Load images & run from reset state
   Or: $0 [--bypass] [--rstsoc] [--minicom] <xdmaN>                                   Continue from last state
Options:
  --bypass   启用 bypass 模式（原 load_and_run_bypass.sh 部分功能）
  --rstsoc   启用 rstsoc 模式（原 load_and_run_rstsoc.sh 部分功能）
  --minicom  启用 minicom 模式（原 load_and_run_minicom.sh 部分功能）
  可组合使用，分别启用对应功能
EOF
    exit 1
}

# 解析选项
bypass=0
rstsoc=0
minicom=0
while [[ "$1" == --* ]]; do
    case "$1" in
        --bypass) bypass=1 ;;
        --rstsoc) rstsoc=1 ;;
        --minicom) minicom=1 ;;
        *) usage ;;
    esac
    shift
done

if [ $# -lt 1 ]; then
    usage
fi

xdma_user=/dev/${1}_user
xdma_bypass=/dev/${1}_bypass

if [ ! -c $xdma_user ]; then
    echo "ERROR: not a character device: $xdma_user"
    exit 1
fi
if [ $bypass -eq 1 ] && [ ! -c $xdma_bypass ]; then
    echo "ERROR: not a character device: $xdma_bypass"
    exit 1
fi

if [ $# -eq 1 ]; then
    if [ $minicom -eq 1 ]; then
        minicom -D /dev/ttyUL0
    else
        ./build/pcie-util $xdma_user uart 0x11000
    fi
elif [ $# -eq 3 ]; then
    bootrom=$2
    fw_payload=$3
    if [ ! -f $bootrom ]; then
        echo "ERROR: file not found: $bootrom"
        exit 1
    fi
    if [ ! -f $fw_payload ]; then
        echo "ERROR: file not found: $fw_payload"
        exit 1
    fi
    echo "Assert core reset"
    ./build/pcie-util $xdma_user write 0x100000 1
    if [ $rstsoc -eq 1 ]; then
        echo "Assert SoC resetn"
        ./build/pcie-util $xdma_user write 0x200000 0
    fi
    echo "Load $bootrom"
    ./build/pcie-util $xdma_user load 0x0 0x10000 $bootrom
    if [ $bypass -eq 1 ]; then
        echo "Load $fw_payload (bypass)"
        ./build/pcie-util $xdma_bypass load 0x0 0x10000000 $fw_payload
        # ./build/load_workload 0x0 0x10000000 $fw_payload
    else
        echo "Load $fw_payload (workload)"
        ./build/load_workload 0x80000000 0x10000000 $fw_payload
    fi
    if [ $rstsoc -eq 1 ]; then
        echo "Dessert SoC resetn"
        ./build/pcie-util $xdma_user write 0x200000 1
    fi
    echo "Deassert core reset"
    ./build/pcie-util $xdma_user write 0x100000 0
    if [ $minicom -eq 1 ]; then
        echo "Start serial connection (minicom)"
        minicom -D /dev/ttyUL0
    else
        echo "Start serial connection (uart)"
        ./build/pcie-util $xdma_user uart 0x11000
    fi
else
    usage
fi
