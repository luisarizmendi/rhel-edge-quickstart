#!/bin/bash

blueprint_name="factory-edge"

repo_server_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')


parent_id=$(curl http://$repo_server_ip:8080/repo/refs/heads/rhel/8/x86_64/edge)



##############

composer-cli blueprints push blueprint.toml





composer-cli compose start-ostree --parent $parent_id $blueprint_name edge-commit  > .tmp
image_commit=$(cat .tmp | awk '{print $2}')


# $(!!) Not working in shell script so I use tmp file
echo ""
echo "Creating image..."


composer-cli compose start-ostree $blueprint_name edge-commit > .tmp
image_commit=$(cat .tmp | awk '{print $2}')

# Wait until image is created
RESOURCE="$image_commit"
command="composer-cli compose status"
echo_finish="FINISHED"
while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]; do echo "Waiting for $RESOURCE" && sleep 60; done



# Wait until image is created

echo ""
echo "Downloading image $image_commit..."



mkdir -p images
cd images
composer-cli compose image $image_commit
cd ..



################################################################################
######################################## CREATE REPO CONTAINER
################################################################################

# Stop previous container

echo ""
echo "Stopping previous .."
echo ""


podman stop $(podman ps | grep 0.0.0.0:8080 | awk '{print $1}')

# Start repo container

c

echo ""
echo "Building and running the container serving the image..."


sed "s/<repo_server_ip:port>/$repo_server_ip:8080/g" kickstart.ks.tmp > kickstart.ks


podman build -t ${blueprint_name}-repo:latest --build-arg kickstart=kickstart.ks --build-arg commit=images/${image_commit}-commit.tar .
podman tag ${blueprint_name}-repo:latest ${blueprint_name}-repo:$image_commit
podman run --name ${blueprint_name}-repo-$image_commit -d -p 8080:8080 ${blueprint_name}-repo:latest



echo ""
echo "****************************************************************************************"
echo "OSTree update ready"
echo "****************************************************************************************"
echo ""

