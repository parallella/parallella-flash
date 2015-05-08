#!/bin/bash
set -e

DEFAULT_ETHADDR="04:4f:8b:00:00:00"

BOOT_MD5="08f0fb4f4fbfe5086d8aba6cacece68a"

ENV_MD5="2e2cd0f10a6c8f7d836d0d752507f9b2"
ENV_FILE="env.bin"

BAK_SUFFIX=.$(date +"%Y%m%d%H%M%S").bak.gz

BOOT_BAK=backup/BOOT.bin${BAK_SUFFIX}
ENV_BAK=backup/env.bin${BAK_SUFFIX}

# Helper functions
which_() {
	ret=0
	for p in $@; do
		if ! which $p 1>/dev/null; then
			echo ERROR: no $p in path
			ret=1
		fi
	done
	return $ret
}

i2cdetect_() {
	i2cdetect -r -y 0 $1 $1 >/dev/null || return 1

	if ! i2cdetect -r -y 0 $1 $1 | grep -q -- "--"; then
		return 0
	else
		return 1
	fi
}

getvariant() {
	if i2cdetect_ 0x2f; then
		echo "fmcomms"
	elif i2cdetect_ 0x39; then
		echo "hdmi"
	else
		echo "headless"
	fi
}

cd $(dirname $(readlink -f $0))
PATH=$(pwd):${PATH}

if ! [ "x$(id -u)" = "x0" ]; then
	echo ERROR: Must run script as root
	exit 1
fi

# Check that all needed programs are installed
if ! which_ i2cdetect getfpga fw_printenv fw_setenv strings md5sum grep stat \
	    od tr sed cut gzip zcat; then
	echo ERROR: One or more required programs missing.
	exit 1
fi

# Probe system
if ! [ -e /proc/device-tree/compatible ]; then
	echo ERROR: No device tree
	exit 1
fi

if ! grep -q adapteva,parallella /proc/device-tree/compatible; then
	echo ERROR: Not a parallella board
	exit 1
fi

if ! ./getfpga 2>/dev/null 1>/dev/null; then
	echo ERROR: Did not find ZYNQ FPGA.
	exit 1
fi

FPGA_MODEL=$(./getfpga)
echo -e "FPGA Model:\t${FPGA_MODEL}"

case ${FPGA_MODEL} in
7z010|7z020)
	;;
*)
	echo ERROR: FPGA model not supported
	exit 1
	;;
esac

# TODO: Figure out if we actually need to probe board variant. Do it but ignore
# the result for now.
VARIANT=$(getvariant $FPGA_MODEL)
echo -e "Board variant:\t${VARIANT} (ignoring)"

BOOT_FILE="BOOT.${FPGA_MODEL}.bin"

if ! [ -e ${BOOT_FILE} ]; then
	echo ERROR: ${BOOT_FILE} does not exist
	exit 1
fi
if ! [ -e ${ENV_FILE} ]; then
	echo ERROR: ${ENV_FILE} does not exist
	exit 1
fi

if ! md5sum --quiet -c md5sum.txt; then
	echo ERROR: md5sum check failed.
	exit 1
fi

if ! [ -e /dev/mtdblock0 ]; then
	echo ERROR: No mtdblock0
	exit 1
fi
if ! [ -e /dev/mtdblock1 ]; then
	echo ERROR: No mtdblock1
	exit 1
fi

echo

echo Prepared to start flashing Parallella 7z020 board
echo "Press [Ctrl-C] to abort"
echo WARNING: DO NOT TURN OFF BOARD WHILE FLASHING!!
read -p "Write 'YES' (all caps) if you understand: " confirm
echo

if ! [ "x${confirm}" = "xYES" ]; then
	echo ERROR: Expected 'YES'. Try again
	exit 1
fi


BOOT_SIZE=$(stat -c%s "${BOOT_FILE}")
ENV_SIZE=$(stat -c%s "${ENV_FILE}")


mkdir -p backup
echo Backing up boot image to \"$(pwd)/${BOOT_BAK}\" ...
dd status=none if=/dev/mtdblock0 bs=64k | gzip -c > ${BOOT_BAK} || exit 1
echo Backing up environment image to \"$(pwd)/${ENV_BAK}\" ...
dd status=none if=/dev/mtdblock1 bs=64k | gzip -c > ${ENV_BAK} || exit 1
echo

FLASHED_BOOT_SIZE=$(zcat ${BOOT_BAK} | wc --bytes)
FLASHED_ENV_SIZE=$(zcat ${ENV_BAK} | wc --bytes)

if [ ${BOOT_SIZE} -gt ${FLASHED_BOOT_SIZE} ]; then
	echo ERROR: Boot partition will not fit boot image
	exit 1
fi

if [ ${ENV_SIZE} -gt ${FLASHED_ENV_SIZE} ]; then
	echo ERROR: Environment partition will not fit environment image
	exit 1
fi

sync

echo WARNING: DO NOT TURN OFF BOARD WHILE FLASHING!!
echo Flashing... This will take a couple of minutes. Stay tuned.

echo BOOT image...
dd status=none if=${BOOT_FILE} of=/dev/mtdblock0 bs=64k
echo ENVIRONMENT image...
dd status=none if=${ENV_FILE} of=/dev/mtdblock1 bs=64k

echo Done.
echo

echo Reading back to verify result...

FLASHED_BOOT_MD5=$(dd status=none if=/dev/mtdblock0 bs=${BOOT_SIZE} count=1 |
		   md5sum | cut -f1 -d" ")
if ! [ ${FLASHED_BOOT_MD5} = ${BOOT_MD5} ]; then
	echo ERROR: ${BOOT_FILE}: Checksum does not match.
	echo Try flashing again.
	echo Do not turn off board.
	echo Contact support.
	exit 1
fi
echo BOOT block OK

FLASHED_ENV_MD5=$(dd status=none if=/dev/mtdblock1 bs=${ENV_SIZE} count=1 |
		  md5sum | cut -f1 -d" ")
if ! [ ${FLASHED_ENV_MD5} = ${ENV_MD5} ]; then
	echo ERROR: ${ENV_FILE}: Checksum does not match.
	echo ${FLASHED_ENV_MD5}
	echo ${ENV_MD5}
	echo Try flashing again.
	echo Do NOT turn off board.
	echo Contact support.
	exit 1
fi
echo ENVIRONMENT block OK

echo
echo Extracting board data from old environment...
SKU=$(zcat ${ENV_BAK} | strings | grep AdaptevaSKU  | head -n1 | cut -f2 -d  "=")
ETHADDR=$(zcat ${ENV_BAK} | strings | grep ethaddr | head -n1 | cut -f2 -d "=")

if [ "x${ETHADDR}" = "x" ]; then
	echo Ethernet address not found in environment...
	ETHADDR=$(cat /sys/class/net/eth0/address 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)
fi
if [ "x${ETHADDR}" = "x" -o "x${ETHADDR}" = "x${DEFAULT_ETHADDR}" ]; then
	# Use board prefix but randomize lower three bytes
	ETHADDR=$(od -A n -t x -N 4 /dev/urandom | tr -d ' ' |
		sed -e 's,\(..\)\(..\)\(..\)\(..\),04:4f:8b:\1:\2:\3,g')
	echo Randomizing MAC address. New MAC address: ${ETHADDR}
fi

if [ "x${SKU}" = "x" ]; then
	echo No SKU found. Skipping
else
	echo Setting SKU to ${SKU}
	./fw_setenv AdaptevaSKU ${SKU}
fi

echo Setting MAC address to ${ETHADDR}
./fw_setenv ethaddr ${ETHADDR}

echo
echo Flash successful. Power-cycle your board.


