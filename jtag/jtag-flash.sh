#!/bin/bash

cd $(dirname $(readlink -f $0))

. ../common.sh

setup_path_or_die

if ! [ -e ../BOOT.bin ]; then
    echo BOOT.bin missing. Run mkbootflash.sh first.
    exit 1
fi

if ! [ -e ../env.bin ]; then
    echo env.bin missing.
    exit 1
fi

if ! [ -e ../version.bin ]; then
    echo version.bin missing.
    exit 1
fi

echo Will flash SDK to board in 5 seconds.
echo Make sure you have JTAG connected to the board.
echo Press Ctrl-C to abort.
sleep 5

echo Flashing boot partition...
zynq_flash -f ../BOOT.bin -flash_type qspi_single || exit 1
echo Flashing environment partition...
zynq_flash -offset 0x004e0000 -f ../env.bin -flash_type qspi_single || exit 1
echo Flashing version partition...
zynq_flash -offset 0x00ff0000 -f ../version.bin -flash_type qspi_single || exit 1

echo Done.
