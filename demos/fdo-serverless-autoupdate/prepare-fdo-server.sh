#!/bin/bash

#dnf install -y fdo-admin-cli fdo-manufacturing-server –refresh

#mkdir /root/fdo-keys
#fdo-admin-tool generate-key-and-cert diun --destination-dir fdo-keys
#fdo-admin-tool generate-key-and-cert manufacturer --destination-dir fdo-keys
#fdo-admin-tool generate-key-and-cert device-ca --destination-dir fdo-keys
#fdo-admin-tool generate-key-and-cert owner --destination-dir fdo-keys

service_info_auth_token=$(grep service_info_auth_token /etc/fdo/aio/configs/serviceinfo_api_server.yml | awk '{print $2}')
admin_auth_token=$(grep admin_auth_token /etc/fdo/aio/configs/serviceinfo_api_server.yml | awk '{print $2}')

sed -i "s/service_info_auth_token:*.*/service_info_auth_token: $service_info_auth_token/g" serviceinfo_api_server.yml.example 
sed -i "s/admin_auth_token:*.*/admin_auth_token: $admin_auth_token/g" serviceinfo_api_server.yml.example 

cp -f serviceinfo_api_server.yml.example  /etc/fdo/aio/configs/serviceinfo_api_server.yml


cp -r fdo /etc/

systemctl restart fdo-aio
