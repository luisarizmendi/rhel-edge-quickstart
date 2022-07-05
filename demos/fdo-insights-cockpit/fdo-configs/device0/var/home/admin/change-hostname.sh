#!/bin/bash
hostnamectl set-hostname edge-virt-$(echo $RANDOM | md5sum | head -c 8; echo;)
hostnamectl --pretty set-hostname edge-virt-$(echo $RANDOM | md5sum | head -c 8; echo;)

cp /etc/hostname /mnt/sysroot/etc/hostname
cp /etc/machine-info /mnt/sysroot/etc/machine-info


