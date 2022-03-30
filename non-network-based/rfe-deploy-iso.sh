#!/bin/bash


blueprint_name="factory-edge"


## PRE-REQUISITES

dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion

systemctl enable osbuild-composer.socket --now
systemctl enable cockpit.socket --now

firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent

source  /etc/bash_completion.d/composer-cli

systemctl restart osbuild-composer



################################################################################
######################################## CREATE REPO
################################################################################


 ## passwords:   python3 -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'

### NOTE!!!!:  remember to include a \ before any $ sign in the password hash so the cat does not think is a variable

cat <<EOF > blueprint.toml
name = "$blueprint_name"
description = "Sample blueprint"
version = "0.0.1"
modules = [ ]
groups = [ ]

[[packages]]
name = "tree"
version = "*"

[customizations]
hostname = "edge-node"

[[customizations.sshkey]]
user = "root"
key = '<your ssh pub key>'

[[customizations.user]]
name = "core"
description = "Core user"
password = '<your password hash>'
key = '<your key>'
home = "/home/core/"
shell = "/usr/bin/bash"
groups = ["users", "wheel"]

EOF


cat <<EOF > blueprint-iso.toml
name = "${blueprint_name}-iso"
description = "Blueprint for ISOs"
version = "0.0.1"
modules = [ ]
groups = [ ]
EOF



composer-cli blueprints push blueprint.toml

composer-cli blueprints push blueprint-iso.toml



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




host_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')





# Start repo container

cat ${image_commit_name}-container.tar | podman load  > .tmp

container_image_id=$(cat .tmp | grep "Loaded image" | awk -F 'sha256:' '{print $2}')


podman tag $container_image_id localhost/${blueprint_name}-install-repo-$image_commit_name

podman run --name=${blueprint_name}-install-repo-$image_commit_name -d  -p 8081:8080 localhost/${blueprint_name}-install-repo-$image_commit_name

# Wait for container to be running
until [ "$(sudo podman inspect -f '{{.State.Running}}' ${blueprint_name}-install-repo-${image_commit_name})" == "true" ]; do
    sleep 1;
done;


## kickstart could be added with a command like this:
# podman run --rm -p 8000:80 -v ./edge.ks:/var/www/html/edge.ks:z edge-server




################################################################################
######################################## Create ISO
################################################################################



#composer-cli compose start-ostree ${blueprint_name}-iso edge-simplified-installer --ref rhel/8/x86_64/edge --url http://$host_ip:8081/repo/
composer-cli compose start-ostree ${blueprint_name}-iso edge-installer --ref rhel/8/x86_64/edge --url http://$host_ip:8081/repo/ > .tmp
image_commit_name=$(cat .tmp | awk '{print $2}')

echo ""
echo "Creating ISO..."
echo ""

RESOURCE="$image_commit_name"
command="composer-cli compose status"
echo_finish="FINISHED"
while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]; do echo "Waiting for $RESOURCE" && sleep 10; done


echo ""
echo "Downloading ISO $image_commit_name..."
composer-cli compose image $image_commit_name
echo ""




echo ""
echo "****************************************************************************************"
echo "Install using this ISO with UEFI boot loader!!! (otherwise you will get error code 0009)"
echo "****************************************************************************************"
echo ""
echo ""
