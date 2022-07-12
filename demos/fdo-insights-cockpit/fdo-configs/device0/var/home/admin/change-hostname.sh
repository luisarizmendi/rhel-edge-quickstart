#!/bin/bash

if [ $(hostname --short) == "localhost" ]
then
this_hostname=$(echo $RANDOM | md5sum | head -c 8; echo;)
hostnamectl set-hostname edge-virt-${this_hostname}
hostnamectl --pretty set-hostname edge-virt-${this_hostname}
fi