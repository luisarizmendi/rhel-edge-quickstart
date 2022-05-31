#!/bin/bash
iso=$1

if [ -z "$iso" ]
then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "You must define the ISO file"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        echo "Example: $0 images/my-arm-rhel.iso"
        echo ""
        Help
        exit -1

fi


if [ -f "$iso" ]
then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "ISO file does not exist"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        echo ""
        Help
        exit -1

fi

      
      echo ""
      echo ""
      echo "Adding Raspberry PI UEFI bootloader to ISO..."
      echo ""

      mkdir -p mnt/rhel-iso/
      mount -o loop $iso mnt/rhel-iso/


      shopt -s dotglob
      mkdir -p tmp/rhel-iso
      cp -avRf mnt/rhel-iso/* tmp/rhel-iso








      iso_label=$(blkid $iso | awk -F 'LABEL="' '{print $2}' | cut -d '"' -f 1)

      cd tmp/rhel-iso



         sed -i 's/timeout=60/timeout=1/g' EFI/BOOT/grub.cfg

         #sed -i "s/quiet/inst.ks=hd:LABEL=${iso_label}:\/ks.cfg/g" EFI/BOOT/grub.cfg
         sed -i "s/inst.stage2/inst.ks=http:\/\/${repo_server_ip}:${repo_server_port}\/${kickstart_file} inst.stage2/g" EFI/BOOT/grub.cfg
         sed -i "s/RHEL-.-.-0-BaseOS-${basearch}/${iso_label}/g" EFI/BOOT/grub.cfg



         rm -rf ../../images/${image_commit}-custom-kernelarg.iso


         xorriso -as mkisofs -V ${iso_label} -r -o ../../images/${image_commit}-custom-kernelarg.iso -J -joliet-long -cache-inodes -efi-boot-part --efi-boot-image -e images/efiboot.img -no-emul-boot .



         implantisomd5 ../../images/${image_commit}-custom-kernelarg.iso





      cd ../../


      umount mnt/rhel-iso
      rm -rf mnt
      rm -rf tmp



