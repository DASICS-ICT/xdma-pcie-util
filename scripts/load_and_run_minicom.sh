#!/bin/bash

if [ $# -ge 1 ]; then
    xdma_user=/dev/${1}_user
    if [ ! -c $xdma_user ]; then
        echo "ERROR: not a character device: $xdma_user"
        exit 1
    fi
fi

if [ $# -eq 1 ]; then

    minicom -D /dev/ttyUL0

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

    # echo "Assert SoC resetn"
    # ./build/pcie-util $xdma_user write 0x200000 0

    echo "Load $bootrom"
    ./build/pcie-util $xdma_user load 0x0 0x10000 $bootrom

    echo "Load $fw_payload"
    ./build/load_workload 0x80000000 0x10000000 $fw_payload

    # echo "Dessert SoC resetn"
    # ./build/pcie-util $xdma_user write 0x200000 1

    echo "Deassert core reset"
    ./build/pcie-util $xdma_user write 0x100000 0

    echo "Start serial connection"
    minicom -D /dev/ttyUL0

else

cat <<EOF
Usage: $0 <xdmaN> <bootrom.bin> <fw_payload.bin>    Load images & run from reset state
   Or: $0 <xdmaN>                                   Continue from last state
EOF
exit 1

fi
