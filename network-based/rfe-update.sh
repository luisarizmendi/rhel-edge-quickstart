#!/bin/bash

blueprint_name="factory-edge"


##############

composer-cli blueprints push blueprint.toml


composer-cli compose start-ostree $blueprint_name edge-container  > .tmp
image_commit_name=$(cat .tmp | awk '{print $2}')

echo ""
echo "Creating image..."
echo ""

RESOURCE="$image_commit_name"
command="composer-cli compose status"
echo_finish="FINISHED"
while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]; do echo "Waiting for $RESOURCE" && sleep 10; done

echo ""
echo "Downloading image $image_commit_name..."
composer-cli compose image $image_commit_name
echo ""


################################################################################
######################################## CREATE REPO CONTAINER
################################################################################

# Stop previous container

podman stop $(podman ps | grep 0.0.0.0:8080 | awk '{print $1}')

# Start repo container

cat ${image_commit_name}-container.tar | podman load  > .tmp

container_image_id=$(cat .tmp | grep "Loaded image" | awk -F 'sha256:' '{print $2}')


podman tag $container_image_id localhost/${blueprint_name}-repo-$image_commit_name

podman run --name=${blueprint_name}-repo-$image_commit_name -d  -p 8080:8080 localhost/${blueprint_name}-repo-$image_commit_name

# Wait for container to be running
until [ "$(sudo podman inspect -f '{{.State.Running}}' ${blueprint_name}-repo-${image_commit_name})" == "true" ]; do
    sleep 1;
done;

## kickstart could be added with a command like this:
# podman run --rm -p 8000:80 -v ./edge.ks:/var/www/html/edge.ks:z edge-server




echo ""
echo "****************************************************************************************"
echo "OSTree update ready"
echo "****************************************************************************************"
echo ""

