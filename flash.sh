#!/bin/bash

: ${XILINX_SDK_PATH:="/opt/Xilinx/SDK/2014.4"}

function setup_path_or_die() {
    which bootgen >/dev/null && which zynq_flash >/dev/null && return 0

    if ! [ -d `realpath ${XILINX_SDK_PATH}` ]; then
        echo "Could not find Xilinx SDK. Please set XILINX_SDK_PATH"
        exit 1
    fi

    case `uname -m` in
    x86_64)
        settings="settings64.sh"
        ;;

    i686|i386)
        settings="settings32.sh"
        ;;

    *)
        echo Unknown arch. Add it to script.
        exit 1
        ;;

    esac

    if ! [ -e ${XILINX_SDK_PATH}/${settings} ]; then
        echo "Could not find Xilinx SDK. Please set XILINX_SDK_PATH"
        exit 1
    fi

    . ${XILINX_SDK_PATH}/${settings}
}

setup_path_or_die

echo Creating BOOT.bin...
bootgen -w on -image boot.bif -o BOOT.bin || exit 1

echo Will flash SDK to board in 5 seconds.
echo Make sure you have JTAG connected to the board.
echo Press Ctrl-C to abort.
sleep 5

echo Flashing boot partition...
zynq_flash -f BOOT.bin -flash_type qspi_single || exit 1
echo Flashing version partition...
zynq_flash -offset 0x00ff0000 -f version.bin -flash_type qspi_single || exit 1

echo Done.
