#!/bin/bash

: ${XILINX_SDK_PATH:="/opt/Xilinx/SDK/2015.1"}

setup_path_or_die() {
    which bootgen >/dev/null 2>/dev/null &&
        which zynq_flash >/dev/null 2>/dev/null && return 0

    if ! [ -d `realpath ${XILINX_SDK_PATH}` ]; then
        echo "Could not find Xilinx SDK. Please set XILINX_SDK_PATH"
        exit 1
    fi

    case `uname -m` in
    x86_64)
        settings="settings64.sh"
        ;;

    i686|i386)
        echo Detected 32-bit machine. Xilinx dropped 32 bit support.
        exit 1
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
