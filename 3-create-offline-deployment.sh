#!/bin/bash

repo_server_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')
repo_server_port="8080"
simplified_installer=true
raw_image=false;;

############################################################
# Help                                                     #
############################################################


Help()
{
   # Display Help
   echo "This Script creates an ISO (by default for unattended installation) with the OSTree commit embedded to install a system without the need of external network resources (HTTP or PXE server)."
   echo
   echo "Syntax: $0 [-h <IP>|-p <port>]|-a|-r]"
   echo ""
   echo "options:"
   echo "h     Repo server IP (default=$repo_server_ip)."
   echo "p     Repo server port (default=$repo_server_port)."
   echo "a     Anaconda. If enabled (default=disabled), it creates an ISO that will jump into Anaconda instaler, where you will be able to select, among others, the disk where RHEL for edge will be installed"
   echo "r     Create RAW/QCOW2 images instead of an ISO (default=disabled)."
   echo
   echo "Example: $0 -h 192.168.122.129 -p 8081 -a -r"
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
while getopts ":h:p:ar" option; do
   case $option in
      h)
         repo_server_ip=$OPTARG;;
      p)
         repo_server_port=$OPTARG;;
      a)
         simplified_installer=false;;
      r)
         raw_image=true;;
     \?) # Invalid option
         echo "Error: Invalid option"
         echo ""
         Help
         exit -1;;
   esac
done




cat <<EOF > blueprint-iso.toml
name = "blueprint-iso"
description = "Blueprint for ISOs"
version = "0.0.1"
modules = [ ]
groups = [ ]
EOF








if [ $raw_image = false ]
then


   ################################################################################
   ######################################## CREATE ISO
   ################################################################################

   echo ""
   echo "Pushing ISO Blueprint..."

   composer-cli blueprints push blueprint-iso.toml



   # $(!!) Not working in shell script so I use tmp file
   echo ""
   echo "Creating ISO..."


   if [ $simplified_installer = true ]
   then
      composer-cli compose start-ostree blueprint-iso edge-simplified-installer --ref rhel/8/x86_64/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp
   else
      composer-cli compose start-ostree blueprint-iso edge-installer --ref rhel/8/x86_64/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp
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

   if [ $simplified_installer = true ]
   then
   echo "************************************************************************"
   echo "If you are deploying on VMs be sure that the disk is using SATA drivers " 
   echo "instead of VirtIO, in order to get a fully unattendant installation"
   echo "************************************************************************"
   echo ""
   echo ""
   fi



else

   ############################################################
   # RAW image      
   ############################################################

      composer-cli compose start-ostree ${blueprint_name} edge-raw-image --ref rhel/8/x86_64/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp

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
