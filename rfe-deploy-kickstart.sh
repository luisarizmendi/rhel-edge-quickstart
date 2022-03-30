#!/bin/bash


blueprint_name="factory-edge"


## PRE-REQUISITES

yum install -y podman osbuild-composer composer-cli cockpit-composer bash-completion

systemctl enable osbuild-composer.socket --now
systemctl enable cockpit.socket --now

firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent

source  /etc/bash_completion.d/composer-cli

systemctl restart osbuild-composer




################################################################################
######################################## CREATE REPO
################################################################################


# password hash:   python3 -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'


cat <<EOF > blueprint.toml
name = "$blueprint_name"
description = "Sample blueprint"
version = "0.0.1"
modules = [ ]
groups = [ ]

[[packages]]
name = "tmux"
version = "*"

[customizations]
hostname = "edge-node"

[[customizations.sshkey]]
user = "root"
key = "<key>"

[[customizations.user]]
name = "core"
description = "Core user"
password = "<your password hash>"
key = "<your key>"
home = "/home/core/"
shell = "/usr/bin/bash"
groups = ["users", "wheel"]

EOF




composer-cli blueprints push blueprint.toml

# $(!!) Not working in shell script so I use tmp file

composer-cli compose start-ostree $blueprint_name edge-commit > .tmp
image_commit_name=$(cat .tmp | awk '{print $2}')

RESOURCE="$image_commit_name"
command="composer-cli compose status"
echo_finish="FINISHED"
while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]; do echo "Waiting for $RESOURCE" && sleep 10; done


echo ""
echo "Downloading image $image_commit_name..."
composer-cli compose image $image_commit_name
echo ""






################################################################################
######################################## PUBLISH IMAGE
################################################################################



echo ""
echo ""
echo "************************************************************************"
echo ""
echo "USING COMMIT IMAGE $image_commit_name"
echo ""
echo "************************************************************************"
echo ""
echo ""
echo ""



host_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')


tar xvf ${image_commit_name}-commit.tar



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

ostreesetup --nogpg --osname=rhel --remote=edge --url=http://$host_ip:8080/repo/ --ref=rhel/8/x86_64/edge

%post
cat << EOF > /etc/greenboot/check/required.d/check-dns.sh
#!/bin/bash

DNS_SERVER=\$(grep nameserver /etc/resolv.conf | cut -f2 -d" ")
COUNT=0

# check DNS server is available
ping -c1 \$DNS_SERVER
while [ \$? != '0' ] && [ \$COUNT -lt 10 ]; do
((COUNT++))
echo "Checking for DNS: Attempt \$COUNT ."
sleep 10
ping -c 1 \$DNS_SERVER
done
EOF
%end

EOFIN






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







#commit=$(jq '.["ostree-commit"]' < compose.json | awk -F '"' '{print $2}')

podman build -t ${blueprint_name}-commit-repo-$image_commit_name --build-arg kickstart=kickstart.ks --build-arg commit=${image_commit_name}-commit.tar .

podman run --name ${blueprint_name}-commit-repo-$image_commit_name -d -p 8080:8080 localhost/${blueprint_name}-commit-repo-$image_commit_name


echo ""
echo ""
echo ""
echo ""
echo "Install using ISO including in kernel arguments this string at the end:"
echo ""
echo "************************************************************************"
echo ""
echo "<kernel args> inst.ks=http://$host_ip:8080/kickstart.ks"
echo ""
echo "************************************************************************"
echo ""
echo ""
echo ""
