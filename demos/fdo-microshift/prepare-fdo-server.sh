#!/bin/bash

VAR_FILE=.vars

firewall-cmd --add-port=8080-8083/tcp --permanent
firewall-cmd --reload



# This crazy stuff is because it didn't work with just removing the file and restarting the service...
systemctl stop fdo-aio
sleep 1
rm -rf /etc/fdo/aio/*
dnf install -y fdo-admin-cli fdo-manufacturing-server
systemctl enable --now fdo-aio
rm -rf /etc/fdo/aio/*
sleep 1
systemctl restart fdo-aio


#mkdir /root/fdo-keys
#fdo-admin-tool generate-key-and-cert diun --destination-dir fdo-keys
#fdo-admin-tool generate-key-and-cert manufacturer --destination-dir fdo-keys
#fdo-admin-tool generate-key-and-cert device-ca --destination-dir fdo-keys
#fdo-admin-tool generate-key-and-cert owner --destination-dir fdo-keys





if [ -f "$VAR_FILE" ]; then
    RHORGID=$(grep RHORGID $VAR_FILE | awk -F RHORGID= '{print $2}')
    ACTIVATIONKEY=$(grep ACTIVATIONKEY $VAR_FILE | awk -F ACTIVATIONKEY= '{print $2}')
    SSHKEY=$(grep SSHKEY $VAR_FILE | awk -F SSHKEY= '{print $2}')
else
    echo ""

    echo ""
    echo "Enter your Red Hat Organization ID:"
    read RHORGID

    echo ""
    echo "Enter your Red Hat Activation Key:"
    read ACTIVATIONKEY

    echo ""
    echo "Enter your Public SSH Key:"
    read SSHKEY
fi






sleep 5

service_info_auth_token=$(grep service_info_auth_token /etc/fdo/aio/configs/serviceinfo_api_server.yml | awk '{print $2}')
admin_auth_token=$(grep admin_auth_token /etc/fdo/aio/configs/serviceinfo_api_server.yml | awk '{print $2}')


yes | cp -f serviceinfo_api_server.yml.example serviceinfo_api_server.yml

sed -i "s/<MY_ORGID>/${RHORGID}/g" serviceinfo_api_server.yml 
sed -i "s/<MY_ACTIVATIONKEY>/${ACTIVATIONKEY}/g" serviceinfo_api_server.yml 
sed -i "s|ssh-rsa AAAA|${SSHKEY}|g" serviceinfo_api_server.yml 

sed -i "s|service_info_auth_token:*.*|service_info_auth_token: ${service_info_auth_token}|g" serviceinfo_api_server.yml.example 
sed -i "s|admin_auth_token:*.*|admin_auth_token: ${admin_auth_token}|g" serviceinfo_api_server.yml.example 


rm -rf  /etc/fdo/aio/configs/serviceinfo_api_server.yml
cp -f serviceinfo_api_server.yml  /etc/fdo/aio/configs/serviceinfo_api_server.yml

rm -rf /etc/fdo-configs
cp -r fdo-configs /etc/

sleep 1 

systemctl restart fdo-aio
