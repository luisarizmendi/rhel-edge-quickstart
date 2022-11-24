#!/bin/bash


## PRE-REQUISITES


if [ $(arch) = aarch64 ]
then
    dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion isomd5sum genisoimage jq buildah 
else
    dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion isomd5sum genisoimage jq buildah syslinux firewalld
fi



systemctl enable osbuild-composer.socket --now
systemctl enable cockpit.socket --now
systemctl enable firewalld.service --now

firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent 2>/dev/null

firewall-cmd --add-port=8090-8091/tcp --permanent 2>/dev/null
firewall-cmd --reload 2>/dev/null

systemctl restart firewalld 2>/dev/null

source  /etc/bash_completion.d/composer-cli

systemctl restart osbuild-composer




