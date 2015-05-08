linux-flash
===========

This script can be used to flash a live Parallella system from the command
line in linux.

File           | Description
---------------|---------------------------------------------------------------
linux-flash.sh | Flash script
               |
backup         | The flash script will place backups here
               |
BOOT.7z020.bin | Boot flash image. Created by ../mkbootflash.sh
               |
env.bin        | Created with:
               | uboot/tools/mkenvimage -s 0x20000 -o env.bin ../env.txt
               |
getfpga        | Print on-board FPGA-type (e.g. "7z010" "7z020" ...)
getfpga.c      | gcc getfpga.c -o getfpga
               |
               |
fw_printenv    | Tools to read and write uboot environment partition
fw_setenv      |
uboot--.patch  | Patch that embeds Parallella flash configuration in above
               | two binaries.
               |
md5sum.txt     | Checksum file linux-flash.sh uses to verify that the files to
               | be flashed are not corrupt.
