#!/bin/bash
hostnamectl set-hostname edge-virt-$(echo $RANDOM | md5sum | head -c 8; echo;)
hostnamectl --pretty set-hostname edge-virt-$(echo $RANDOM | md5sum | head -c 8; echo;)