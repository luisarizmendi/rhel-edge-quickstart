#!/bin/bash


## PRE-REQUISITES


if [ $(arch) = aarch64 ]
then
    dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion isomd5sum genisoimage jq buildah fdo-admin-cli
else
    dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion isomd5sum genisoimage jq buildah syslinux fdo-admin-cli
fi


systemctl enable --now fdo-aio
sed -i "s/8080/8090/g" /etc/fdo/aio/configs/manufacturing_server.yml
systemctl restart fdo-aio


systemctl enable osbuild-composer.socket --now
systemctl enable cockpit.socket --now

firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent

source  /etc/bash_completion.d/composer-cli

systemctl restart osbuild-composer




