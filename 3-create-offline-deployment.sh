#!/bin/bash

repo_server_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')
repo_server_port="8080"
simplified_installer=true
raw_image=false
baserelease=$(cat /etc/redhat-release | awk '{print $6}' | awk -F . '{print $1}')
basearch=$(arch)
fdo_server=""
disk_device="sda"


############################################################
# Help                                                     #
############################################################


Help()
{
   # Display Help
   echo "This Script creates an ISO (by default for unattended installation) with the OSTree commit embedded to install a system without the need of external network resources (HTTP or PXE server)."
   echo
   echo "Syntax: $0 [-h <IP>|-p <port>]|-d|-a|-r|-f|-F <server>]]"
   echo ""
   echo "options:"
   echo "h     Repo server IP (default=$repo_server_ip)."
   echo "p     Repo server port (default=$repo_server_port)."
   echo "a     Anaconda. If enabled (default=disabled), it creates an ISO that will jump into Anaconda instaler, where you will be able to select, among others, the disk where RHEL for edge will be installed"
   echo "d     Disk drive where to install the OS (default=sda). Required if not using complete automated install (not using -a)."
   echo "r     Create RAW/QCOW2 images instead of an ISO (default=disabled)."
   echo "f     Use FDO (default=disabled , server=http://$repo_server_ip:8083)."
   echo "F     Use FDO and include a different FDO server URL"
   echo
   echo "Example 1: $0 -h 192.168.122.129 -p 8080 -f -d vda"
   echo "Example 1: $0 -h 192.168.122.129 -p 8080 -F http://10.0.0.2:8083"
   echo "Example 2: $0 -h 192.168.122.129 -p 8080 -r"
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
while getopts ":h:d:F:p:arf" option; do
   case $option in
      h)
         repo_server_ip=$OPTARG;;
      p)
         repo_server_port=$OPTARG;;
      F)
         fdo_server=$OPTARG;;
      d)
         disk_device=$OPTARG;;
      a)
         simplified_installer=false;;
      r)
         raw_image=true;;
      f)
         fdo_server="http://$repo_server_ip:8083";;
     \?) # Invalid option
         echo "Error: Invalid option"
         echo ""
         Help
         exit -1;;
   esac
done





if [ $fdo_server = "" ]
then

cat <<EOF > blueprint-iso.toml
name = "blueprint-iso"
description = "Blueprint for ISOs"
version = "0.0.1"
modules = [ ]
groups = [ ]

[customizations]
installation_device = "/dev/${disk_device}"
EOF

iso_blueprint="blueprint-iso"

else

cat <<EOF > blueprint-fdo.toml
name = "blueprint-fdo"
description = "Blueprint for FDO"
version = "0.0.1"
packages = []
modules = []
groups = []
distro = ""

[customizations]
installation_device = "/dev/${disk_device}"

[customizations.fdo]
manufacturing_server_url = "${fdo_server}"
diun_pub_key_insecure = "true"
EOF

iso_blueprint="blueprint-fdo"

fi






if [ $raw_image = false ]
then


   ################################################################################
   ######################################## CREATE ISO
   ################################################################################

   echo ""
   echo "Pushing ISO Blueprint..."

   composer-cli blueprints push ${iso_blueprint}.toml



   # $(!!) Not working in shell script so I use tmp file
   echo ""
   echo "Creating ISO..."


   if [ $simplified_installer = true ]
   then
      composer-cli compose start-ostree ${iso_blueprint} edge-simplified-installer --ref rhel/${baserelease}/${basearch}/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp
   else
      composer-cli compose start-ostree ${iso_blueprint} edge-installer --ref rhel/${baserelease}/${basearch}/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp
   fi





   image_commit=$(cat .tmp | awk '{print $2}')

   # Wait until image is created
   RESOURCE="$image_commit"
   command="composer-cli compose status"
   echo_finish="FINISHED"
   echo_failed="FAILED"
   while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]
   do 
      if [[ $($command | grep "$RESOURCE" | grep $echo_failed > /dev/null ; echo $?) != "1" ]]
      then
         echo ""
         echo "!!!!!!!!!!!!!!!!!!!!!!!!"
         echo "Error creating the image"
         echo "!!!!!!!!!!!!!!!!!!!!!!!!"
         echo ""
         exit -1
      fi
      echo "Waiting for $RESOURCE" && sleep 60
   done



   # Wait until image is created

   echo ""
   echo "Downloading ISO $image_commit..."



   mkdir -p images
   cd images
   composer-cli compose image $image_commit
   cd ..

   echo $image_commit > .lastimagecommit




   echo ""
   echo "************************************************"
   echo "Install using this ISO with UEFI boot loader!!! "
   echo "(otherwise you will get error code 0009)"
   echo "************************************************"
   echo ""
   echo ""


else

   ############################################################
   # RAW image      
   ############################################################

      echo ""
      echo "Pushing ISO Blueprint..."

      composer-cli blueprints push ${iso_blueprint}.toml


      composer-cli compose start-ostree ${iso_blueprint} edge-raw-image --ref rhel/${baserelease}/${basearch}/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp

      image_commit=$(cat .tmp | awk '{print $2}')

      # Wait until image is created
      RESOURCE="$image_commit"
      command="composer-cli compose status"
      echo_finish="FINISHED"
      echo_failed="FAILED"
      while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]
      do 
         if [[ $($command | grep "$RESOURCE" | grep $echo_failed > /dev/null ; echo $?) != "1" ]]
         then
            echo ""
            echo "!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "Error creating the image"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!"
            echo ""
            exit -1
         fi
         echo "Waiting for $RESOURCE" && sleep 60
      done



      # Wait until image is created

      echo ""
      echo "Downloading ISO $image_commit..."



      mkdir -p images
      cd images
      composer-cli compose image $image_commit

      xz -d $image_commit-image.raw.xz 
      qemu-img convert -f raw $image_commit-image.raw -O qcow2 $image_commit-image.qcow2

      cd .. 
     

      if [ $raw_image = true ]
      then
      echo "*********************************************************************************************"
      echo "RAW and QCOW2 images created"
      echo "*********************************************************************************************"
      echo ""
      echo ""
      fi

fi





echo ""
