#!/bin/bash


XDG_RUNTIME_DIR=/run/user/$(grep admin /lib/passwd | awk -F : '{print $3}')
echo "export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >> /var/home/admin/.bashrc
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR

# fix ownership of user local files and SELinux contexts
chown -R admin: /var/home/admin
restorecon -vFr /var/home/admin



node_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')

sed -i "s/0.0.0.0/${node_ip}/g" /var/home/admin/.config/systemd/user/container-httpd-proxy.socket

sleep 3

systemctl daemon-reload
runuser -l admin -c  " export XDG_RUNTIME_DIR=/run/user/$(grep admin /lib/passwd | awk -F : '{print $3}') ; systemctl --user daemon-reload"


runuser -l admin -c  " export XDG_RUNTIME_DIR=/run/user/$(grep admin /lib/passwd | awk -F : '{print $3}') ; systemctl --user restart pre-pull-container-image.service"
runuser -l admin -c  " export XDG_RUNTIME_DIR=/run/user/$(grep admin /lib/passwd | awk -F : '{print $3}') ; systemctl --user restart podman-auto-update.timer"


runuser -l admin -c  " export XDG_RUNTIME_DIR=/run/user/$(grep admin /lib/passwd | awk -F : '{print $3}') ; systemctl --user restart container-httpd-proxy.socket"
sleep 1
runuser -l admin -c  " export XDG_RUNTIME_DIR=/run/user/$(grep admin /lib/passwd | awk -F : '{print $3}') ; systemctl --user restart container-httpd-proxy.service"



#chmod -R 600 /etc/ssh/*key
