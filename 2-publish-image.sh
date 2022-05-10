#!/bin/bash

image_commit=""
blueprint_name=""
repo_server_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')
repo_server_port="8080"
kickstart_file=""
http_boot_mode=false
http_boot_port=""
iso_kickstart_mode=false
iso_standard=""
basearch=$(arch)

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This Script creates a container with the ostree repo from an edge-commit image"
   echo ""
   echo "Syntax: $0 [-i <image ID>|-h <IP>|-p <port>|-k <KS file>]|-x <port>|-e <standard ISO file>]]"
   echo ""
   echo "options:"
   echo "i     Image ID to be published (required)."
   echo "h     Repo server IP (default=$repo_server_ip)."
   echo "p     Repo server port (default=$repo_server_port)."
   echo "k     Kickstart file. If not defined kickstart.ks is autogenerated."
   echo "x     Create UEFI HTTP Boot server on this port. If enabled (default=disabled) it creates an ISO and publish it on this server. You need to include option -e "
   echo "e     Path to RHEL boot ISO. It will Embedd the kickstart in a new ISO so you don't need to modify kernel args during boot(default=disabled)"
   echo ""
   echo "Example: $0 -i 125c1433-2371-4ae9-bda3-91efdbb35b92"
   echo "Example: $0 -i 125c1433-2371-4ae9-bda3-91efdbb35b92 -h 192.168.122.129 -p 8080 -k kickstart.v1.ks -x 8081 -e images/rhel-8.5-${basearch}-boot.iso"
   echo ""
}



############################################################
############################################################
# Main program                                             #
############################################################
############################################################



############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":i:h:p:k:x:e:" option; do
   case $option in
      i)
         image_commit=$OPTARG;;
      h)
         repo_server_ip=$OPTARG;;
      p)
         repo_server_port=$OPTARG;;
      k)
         kickstart_file=$OPTARG;;
      x)
         http_boot_mode=true
         http_boot_port=$OPTARG;;
      e)
         iso_kickstart_mode=true
         iso_standard=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         echo ""
         Help
         exit -1;;
   esac
done

if [ -z "$image_commit" ]
then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "You must define the Commit ID with option -c"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        echo ""
        Help
        exit -1

fi



if [ $iso_kickstart_mode = false ]  && [ $http_boot_mode = true ]
then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "If you want to use UEFI HTTP boot you need to create a custom iso too!"
        echo "Please, introduce the path to default RHEL ISO with -e"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        echo ""
        Help
        exit -1

fi



if [ -z "$kickstart_file" ]
then

cat <<EOFIN > kickstart.ks
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc
text
zerombr
clearpart --all --initlabel
autopart
reboot
user --name=core --group=wheel
network --bootproto=dhcp --device=link --activate --onboot=on

ostreesetup --nogpg --osname=rhel --remote=edge --url=http://${repo_server_ip}:${repo_server_port}/repo/ --ref=rhel/8/${basearch}/edge

%post
cat << EOF > /etc/greenboot/check/required.d/check-dns.sh
#!/bin/bash

DNS_SERVER=$(grep nameserver /etc/resolv.conf | cut -f2 -d" ")
COUNT=0

# check DNS server is available
ping -c1 $DNS_SERVER
while [ $? != '0' ] && [ $COUNT -lt 10 ]; do
((COUNT++))
echo "Checking for DNS: Attempt $COUNT ."
sleep 10
ping -c 1 $DNS_SERVER
done
EOF
%end

EOFIN

kickstart_file="kickstart.ks"

fi


blueprint_name=$(composer-cli compose status | grep $image_commit | awk '{print $8}')



cat <<EOF > nginx.conf
events {
}
http {
    server{
        listen 8080;
        root /usr/share/nginx/html;
        location / {
            autoindex on;
            }
        }
     }
pid /run/nginx.pid;
daemon off;
EOF


cat <<EOF > Dockerfile
FROM registry.access.redhat.com/ubi8/ubi
RUN yum -y install nginx && yum clean all
ARG kickstart
ARG commit
ADD \$kickstart /usr/share/nginx/html/
ADD \$commit /usr/share/nginx/html/
ADD nginx.conf /etc/
EXPOSE 8080
CMD ["/usr/sbin/nginx", "-c", "/etc/nginx.conf"]
EOF

############################################################
# Download the image.
############################################################


echo ""
echo "Downloading image $image_commit..."



mkdir -p images
cd images
composer-cli compose image $image_commit
cd ..

echo $image_commit > .lastimagecommit



############################################################
# Publish the image.
############################################################


# Stop previous container

echo ""
echo "Stopping previous .."
echo ""

runing_container=$(podman ps | grep 0.0.0.0:$repo_server_port | awk '{print $1}')
podman stop $runing_container 2>/dev/null
podman rm $runing_container 2>/dev/null


# Start repo container


echo ""
echo "Building and running the container serving the image..."


podman build -t ${blueprint_name}-repo:latest --build-arg kickstart=${kickstart_file} --build-arg commit=images/${image_commit}-commit.tar .
podman tag ${blueprint_name}-repo:latest ${blueprint_name}-repo:$image_commit
podman run --name ${blueprint_name}-repo-$image_commit -d -p  $repo_server_port:8080 ${blueprint_name}-repo:$image_commit


# Wait for container to be running
until [ "$(sudo podman inspect -f '{{.State.Running}}' ${blueprint_name}-repo-$image_commit)" == "true" ]; do
    sleep 1;
done;










if [ $iso_kickstart_mode = true ]
then
############################################################
# Embedd kickstart in the ISO
############################################################

# steps from ->  https://access.redhat.com/solutions/60959


echo ""
echo ""
echo "Creating ISO image with kickstart embedded..."
echo ""

mkdir -p mnt/rhel-iso/
mount -o loop $iso_standard mnt/rhel-iso/


shopt -s dotglob
mkdir -p tmp/rhel-iso
cp -avRf mnt/rhel-iso/* tmp/rhel-iso


# Kickstart could be imported into the image and be used instead downloading from the HTTP server... but modifiying the kickstart in the HTTP server is easier...
#cp ${kickstart_file} tmp/rhel-iso/ks.cfg




iso_label=$(blkid $iso_standard | awk -F 'LABEL="' '{print $2}' | cut -d '"' -f 1)
#iso_label=$(grep RHEL isolinux/isolinux.cfg | head -n 1 | awk '{print $3}' | cut -d "=" -f 3)

cd tmp/rhel-iso


#sed -i "s/quiet/inst.ks=hd:LABEL=${iso_label}:\/ks.cfg/g" isolinux/isolinux.cfg
sed -i "s/quiet/inst.ks=http:\/\/${repo_server_ip}:${repo_server_port}\/${kickstart_file}/g" isolinux/isolinux.cfg
sed -i 's/timeout 600/timeout 1/g' isolinux/isolinux.cfg
sed -i "s/RHEL-.-.-0-BaseOS-${basearch}/${iso_label}/g" isolinux/isolinux.cfg


sed -i 's/timeout 60/timeout 1/g' isolinux/grub.conf
sed -i 's/timeout=60/timeout=1/g' EFI/BOOT/BOOT.conf
sed -i 's/timeout=60/timeout=1/g' EFI/BOOT/grub.cfg

#sed -i "s/quiet/inst.ks=hd:LABEL=${iso_label}:\/ks.cfg/g" EFI/BOOT/grub.cfg
sed -i "s/quiet/inst.ks=http:\/\/${repo_server_ip}:${repo_server_port}\/${kickstart_file}/g" EFI/BOOT/grub.cfg
sed -i "s/RHEL-.-.-0-BaseOS-${basearch}/${iso_label}/g" EFI/BOOT/grub.cfg



rm -rf ../../images/${image_commit}-custom-kernelarg.iso




## LEGACY boot
#mkisofs -o ../../images/${image_commit}-custom-kernelarg.iso -b isolinux/isolinux.bin -c isolinux/boot.cat --joliet-long --no-emul-boot --boot-load-size 4 --boot-info-table -J -R -V  "${iso_label}" .
#isohybrid ../../images/${image_commit}-custom-kernelarg.iso


# UEFI boot
mkisofs -o ../../images/${image_commit}-custom-kernelarg.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -graft-points -J -R -l  -V "${iso_label}" .
isohybrid --uefi  ../../images/${image_commit}-custom-kernelarg.iso


implantisomd5 ../../images/${image_commit}-custom-kernelarg.iso

cd ../../


umount mnt/rhel-iso
rm -rf mnt
rm -rf tmp


fi








if [ $http_boot_mode = true ]
then
############################################################
# UEFI HTTP Boot server
############################################################

# info about the setup on libvirt:  https://www.redhat.com/sysadmin/uefi-http-boot-libvirt




# libvirt network example:

# <network xmlns:dnsmasq="http://libvirt.org/schemas/network/dnsmasq/1.0">
#   <name>default</name>
#   <uuid>3328ebe7-2202-4e3b-9ca3-9ddf357db576</uuid>
#   <forward mode="nat">
#     <nat>
#       <port start="1024" end="65535"/>
#     </nat>
#   </forward>
#   <bridge name="virbr0" stp="on" delay="0"/>
#   <mac address="52:54:00:16:0e:63"/>
#   <ip address="192.168.122.1" netmask="255.255.255.0">
#     <tftp root="/var/lib/tftpboot"/>
#     <dhcp>
#       <range start="192.168.122.2" end="192.168.122.254"/>
#       <bootp file="pxelinux.0"/>
#     </dhcp>
#   </ip>
#   <dnsmasq:options>
#     <dnsmasq:option value="dhcp-vendorclass=set:efi-http,HTTPClient:Arch:00016"/>
#     <dnsmasq:option value="dhcp-option-force=tag:efi-http,60,HTTPClient"/>
#     <dnsmasq:option value="dhcp-boot=tag:efi-http,&quot;http://192.168.122.128:8081/EFI/BOOT/BOOTX64.EFI&quot;"/>
#   </dnsmasq:options>
# </network>



# Create VM:
# sudo virt-install   --name=edge-node-uefi-boot   --ram=2048   --vcpus=1   --os-type=linux   --os-variant=rhel8.5   --graphics=vnc   --pxe   --disk size=20,bus=sata  --check path_in_use=off   --network=network=default,model=virtio   --boot=uefi





# dhcpd example

#   class "pxeclients" {
#      match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
#      next-server 192.168.111.1;
#      filename "/bootx64.efi";
#    }
#    class "httpclients" {
#      match if substring (option vendor-class-identifier, 0, 10) = "HTTPClient";
#      option vendor-class-identifier "HTTPClient";
#      filename "http://192.168.122.128:8081/EFI/BOOT/BOOTX64.EFI";
#    }







echo ""
echo ""
echo "Creating UEFI HTTP boot server..."
echo ""


# offline fully automated ISO could be used too
#./3-create-offline-deployment.sh -h $repo_server_ip -p $repo_server_port > /dev/null
#iso_file="$(cat .lastimagecommit)-simplified-installer.iso"

iso_file="$(cat .lastimagecommit)-custom-kernelarg.iso"



mkdir -p mnt/rhel-install/
mount -o loop,ro -t iso9660 images/$iso_file mnt/rhel-install/


mkdir -p tmp/boot-server/var/www/html/

cp -R mnt/rhel-install/* tmp/boot-server/var/www/html/

chmod -R +r tmp/boot-server/var/www/html/*


# Changes on simplified ISO
#sed -i 's/linux \/images\/pxeboot\/vmlinuz/linuxefi \/pxeboot\/vmlinuz/g' tmp/boot-server/var/www/html/EFI/BOOT/grub.cfg
#sed -i 's/initrd \/images\/pxeboot\/initrd.img/initrdefi \/pxeboot\/initrd.img/g' tmp/boot-server/var/www/html/EFI/BOOT/grub.cfg
#sed -i "s/coreos.inst.image_file=\/run\/media\/iso\/disk.img.xz/coreos.inst.image_url=http:\/\/${repo_server_ip}:$http_boot_port\/disk.img.xz/g" tmp/boot-server/var/www/html/EFI/BOOT/grub.cfg


sed -i "s/inst.stage2=.* /inst.stage2=http:\/\/${repo_server_ip}:${http_boot_port} /g" tmp/boot-server/var/www/html/EFI/BOOT/grub.cfg



cat <<EOF > Dockerfile-http-boot
FROM registry.access.redhat.com/ubi8/ubi
RUN yum -y install nginx && yum clean all
ARG content
COPY \$content/ /usr/share/nginx/html/
ADD nginx.conf /etc/
EXPOSE 8080
CMD ["/usr/sbin/nginx", "-c", "/etc/nginx.conf"]
EOF




echo ""
echo "Stopping previous .."
echo ""


runing_container=$($(podman ps | grep 0.0.0.0:$http_boot_port | awk '{print $1}'))
podman stop -$runing_container 2>/dev/null
podman rm -$runing_container 2>/dev/null


podman build -f Dockerfile-http-boot -t http-boot:latest --build-arg content="tmp/boot-server/var/www/html" .
podman run --name http-boot-$iso_file -d -p  $http_boot_port:8080 http-boot:latest

umount mnt/rhel-install/
rm -rf mnt
rm -rf tmp



fi








echo ""
echo ""
echo ""
echo ""


if [ $iso_kickstart_mode = false ]
then

echo "************************************************************************"
echo "Install using standard RHEL ISO including this kernel argument:"
echo ""
echo "<kernel args> inst.ks=http://$repo_server_ip:$repo_server_port/${kickstart_file}"
echo "************************************************************************"
echo ""
echo ""

else

echo "************************************************************************"
echo "You can install using the custom ISO ${image_commit}-custom-kernelarg.iso"
echo "************************************************************************"
echo ""
echo ""


if [ $http_boot_mode = true ]
then
echo "******************************************************************************"
echo "You have activated UEFI HTTP boot, be sure that you have your DHCP configured!"
echo "DHCP-boot:  http://$repo_server_ip:$http_boot_port/EFI/BOOT/BOOTX64.EFI"
echo ""
echo "Remember to use UEFI boot (instead legacy BIOS) and NIC as first boot device"
echo ""
echo "Remember that it takes time until boot reaches UEFI HTTP boot (first tries PXE)"
echo ""
echo "Your edge system must have at least 2GB of memory"
echo "******************************************************************************"
echo ""
echo ""
fi


fi

echo ""







