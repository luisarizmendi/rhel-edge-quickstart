#!/bin/bash


## PRE-REQUISITES

dnf install -y podman osbuild-composer composer-cli cockpit-composer bash-completion isomd5sum genisoimage jq syslinux

systemctl enable osbuild-composer.socket --now
systemctl enable cockpit.socket --now

firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent

source  /etc/bash_completion.d/composer-cli

systemctl restart osbuild-composer







cat <<EOF > .gpgdata
Key-Type: 1
Name-Real: Root Superuser
Name-Email: fake@fake.com
Passphrase: redhat
EOF

gpg --batch --gen-key .gpgdata

rm -f .gpgdata

## Add extended repos
# mkdir -p /etc/osbuild-composer/repositories


# for file in $(ls /usr/share/osbuild-composer/repositories/) 
# do

# jq -s 'def deepmerge(a;b):
#   reduce b[] as $item (a;
#     reduce ($item | keys_unsorted[]) as $key (.;
#       $item[$key] as $val | ($val | type) as $type | .[$key] = if ($type == "object") then
#         deepmerge({}; [if .[$key] == null then {} else .[$key] end, $val])
#       elif ($type == "array") then
#         (.[$key] + $val | unique)
#       else
#         $val
#       end)
#     );
#   deepmerge({}; .)' /usr/share/osbuild-composer/repositories/$file additional-repos.json > /etc/osbuild-composer/repositories/$file

# done
