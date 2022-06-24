#!/bin/bash


firewall-cmd --add-port=8080-8083/tcp --permanent
firewall-cmd --reload



sleep 1
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







service_info_auth_token=$(grep service_info_auth_token /etc/fdo/aio/configs/serviceinfo_api_server.yml | awk '{print $2}')
admin_auth_token=$(grep admin_auth_token /etc/fdo/aio/configs/serviceinfo_api_server.yml | awk '{print $2}')

sed -i "/service_info_auth_token:*.*/d" serviceinfo_api_server.yml.example 
sed -i "/admin_auth_token:*.*/d" serviceinfo_api_server.yml.example 

echo "service_info_auth_token: $service_info_auth_token" >> serviceinfo_api_server.yml.example
echo "admin_auth_token: $admin_auth_token" >> serviceinfo_api_server.yml.example






cp -f serviceinfo_api_server.yml.example  /etc/fdo/aio/configs/serviceinfo_api_server.yml

rm -rf /etc/fdo-configs
cp -r fdo-configs /etc/

systemctl restart fdo-aio
