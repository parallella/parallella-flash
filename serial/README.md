#Upgrading flash over serial cable

1. Copy ../BOOT.z70x0.bin and ../env.bin to the boot partition of your
   Parallella-Ubuntu SD-card.

2. Boot Parallella board without SD card

3. Press any key to stop auto-boot (only works on newer flash images)

4. If that does not work and the board tries to boot over TFTP, press CTRL-C a
   couple of times.

5. You will see the uboot prompt

```
zynq-uboot>
```

6. [OPTIONAL] Set MAC address and AdaptevaSKU.
   (These are set set at board assembly)
   The first 6 characters of the MAC address contain the Adapteva assigned
   range of MAC-IDs. The last 6 characters should match the serial number ("SN")
   on the board sticker. The AdaptevaSKU should match the SKU on the sticker
   including the "SKU" at the start.

```
zynq-uboot> setenv ethaddr 04:4f:8b:00:00:00 (for example)
zynq-uboot> setenv AdaptevaSKU SKUA101040    (for example)
```

7. Save ethaddr and AdaptevaSKU to RAM:
```
zynq-uboot> env export -t -s 0x20000 0x3000000 ethaddr AdaptevaSKU
```

8. Insert the uSD card.

9. Write the new uboot image to QSPI flash
```
zynq-uboot> mmc info
zynq-uboot> fatload mmc 0 0x4000000 parallella.XXXX.flash.bin
zynq-uboot> sf probe 0 0 0
zynq-uboot> sf erase 0 0x1000000
zynq-uboot> sf write 0x4000000 0 0x$filesize
```

10. Write default env to QSPI flash
```
zynq-uboot> fatload mmc 0 0x4000000 env.bin
zynq-uboot> sf write 0x4000000 0x4e0000 0x$filesize

zynq-uboot> env import -t -d 0x4000000
```
11. Restore the ethernet address and SKU from step 7.

```
zynq-uboot> env import -t 0x3000000
zynq-uboot> printenv ethaddr
zynq-uboot> printenv AdaptevaSKU
zynq-uboot> saveenv

12. Power down board

13. At this point the board is ready for general use.

