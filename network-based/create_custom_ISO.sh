#!/bin/bash

################
##########  TODO (NOT WORKING) 
###############
###############
###############
###############
###############





iso_path="../ISO"
iso_name="rhel-boot.iso"


## This script creates a custom ISO so you don't have to introduce manually the kernel args while boot the edge device



mkdir -p /tmp/bootiso 
mount -o loop $iso_path/$iso_name  /tmp/bootiso

mkdir /tmp/bootcustom
cp -r /tmp/bootiso/* /tmp/bootcustom

umount /tmp/bootiso && rmdir /tmp/bootiso


chmod -R u+w /tmp/bootcustom
cp kickstart.ks /tmp/bootcustom/isolinux/kickstart.ks


sed -i 's/append\ initrd\=initrd.img/append initrd=initrd.img\ inst.ks\=cdrom:\/kickstart.ks/' /tmp/bootcustom/isolinux/isolinux.cfg

current_path=$(pwd)

cd /tmp/bootcustom
mkisofs -o /tmp/rhel-custom-boot.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V "RHEL x86_64" -R -J -v -T isolinux/. .
cd $current_path

implantisomd5 /tmp/rhel-custom-boot.iso
cp /tmp/rhel-custom-boot.iso $iso_path/rhel-custom-boot.iso
