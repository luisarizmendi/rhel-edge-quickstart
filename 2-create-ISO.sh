#!/bin/bash


blueprint_name="factory-edge"

repo_server_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')
repo_server_port="8080"

################################################################################
######################################## CREATE ISO
################################################################################


# $(!!) Not working in shell script so I use tmp file
echo ""
echo "Creating ISO..."


composer-cli compose start-ostree blueprint-iso edge-installer --ref rhel/8/x86_64/edge --url http://$repo_server_ip:$repo_server_port/repo/ > .tmp
image_commit=$(cat .tmp | awk '{print $2}')

# Wait until image is created
RESOURCE="$image_commit"
command="composer-cli compose status"
echo_finish="FINISHED"
while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]; do echo "Waiting for $RESOURCE" && sleep 60; done



# Wait until image is created

echo ""
echo "Downloading ISO $image_commit..."



mkdir -p images
cd images
composer-cli compose image $image_commit
cd ..




echo ""
echo "******************************************************************************************"
echo "Install using this ISO with UEFI boot loader!!! (otherwise you will get error code 0009)"
echo "******************************************************************************************"
echo ""
echo ""
