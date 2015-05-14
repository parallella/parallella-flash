#TODO

For JTAG flash we need to figure out a way to read back the environment from
flash so that we can extract "ethaddr" and AdaptevaSKU.

Can't find any easy way to read back flash image with Xilinx tools.
Use OpenOCD instead?

##Run jtag-flash.sh

You need a JTAG cable and Xilinx SDK + cable drivers installed.

Drivers here:
/opt/Xilinx/SDK/2015.1/data/xicom/cable_drivers/

The flash script might fail the first time you run it (hw server times out).
If so, try again.

