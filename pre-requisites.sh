#!/bin/bash


## PRE-REQUISITES

dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion isomd5sum genisoimage

systemctl enable osbuild-composer.socket --now
systemctl enable cockpit.socket --now

firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent

source  /etc/bash_completion.d/composer-cli

systemctl restart osbuild-composer

