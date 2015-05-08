#!/bin/bash

cd $(dirname $(readlink -f $0))

. common.sh

setup_path_or_die

echo Creating BOOT.bin...
bootgen -w on -image boot.bif -o BOOT.bin || exit 1
echo Done.
