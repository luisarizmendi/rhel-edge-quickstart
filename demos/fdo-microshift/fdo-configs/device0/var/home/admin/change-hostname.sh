#!/bin/bash

if [ $(hostname --short) == "localhost" ]
then
this_hostname=$(echo $RANDOM | md5sum | head -c 8; echo;)


####### DISABLED WHILE INVESTIGATING MICROSHIFT
#hostnamectl set-hostname edge-${this_hostname}
#hostnamectl --pretty set-hostname edge-${this_hostname}
####### DISABLED WHILE INVESTIGATING MICROSHIFT



cat <<EOF > /etc/hosts
127.0.0.1   edge-${this_hostname} localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         edge-${this_hostname} localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

fi