#!/bin/bash

baserelease=$(cat /etc/redhat-release  | awk '{print $6}' | awk -F . '{print $1}')
basearch=$(arch)

current_dir="$(pwd)"



###### MICROSHIFT REPO

    dnf install -y golang git rpm-build selinux-policy-devel createrepo yum-utils


    git clone https://github.com/openshift/microshift

    cd microshift

    git pull

    make 

    make rpm
    make srpm



    mkdir -p ${current_dir}/microshift/scripts/image-builder/_builds
    cd ${current_dir}/microshift/scripts/image-builder/_builds



    ########
    ######## Copy MicroShift RPM packages
    rm -rf microshift-local 2>/dev/null || true
    cp -TR ${current_dir}/microshift/packaging/rpm/_rpmbuild/RPMS ${current_dir}/microshift/scripts/image-builder/_builds/microshift-local/
    createrepo ${current_dir}/microshift/scripts/image-builder/_builds/microshift-local/ >/dev/null
    ########



cat <<EOF > microshift-local.toml
id = "microshift-local"
name = "MicroShift Local Repo"
type = "yum-baseurl"
url = "file://${current_dir}/microshift/scripts/image-builder/_builds/microshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF




sudo composer-cli sources delete microshift-local 2>/dev/null || true
sudo composer-cli sources add microshift-local.toml






###### OPENSHIFT REPO


# By default use latest OCP release less 2

subscription-manager repos | grep rhocp-4
if [ $? = 0 ]
then
    RHOCP_release="4.$(( $(subscription-manager repos | grep rhocp-4 | awk -F - '{print $2}' | awk -F . '{print $2}' | sort -nr | head -n1) - 2 ))"

    ########
    ######## Download openshift local RPM packages (noarch for python and selinux packages)
    rm -rf openshift-local 2>/dev/null || true
    reposync -n -a ${basearch} -a noarch --download-path openshift-local \
                --repo=rhocp-${RHOCP_release}-for-rhel-${baserelease}-${basearch}-rpms \
                --repo=fast-datapath-for-rhel-${baserelease}-${basearch}-rpms >/dev/null

    # Remove coreos packages to avoid conflicts
    find openshift-local -name \*coreos\* -exec rm -f {} \;

    # Exit if no RPM packages were found
    if [ $(find openshift-local -name '*.rpm' | wc -l) -eq 0 ] ; then
        echo "No RPM packages were found at the 'rhocp rpms' repository. Exiting..."
        exit 1
    fi

    createrepo openshift-local >/dev/null
    ########

cat <<EOF > openshift-local.toml
id = "openshift-local"
name = "OpenShift Local Repo"
type = "yum-baseurl"
url = "file://${current_dir}/microshift/scripts/image-builder/_builds/openshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF


sudo composer-cli sources delete openshift-local 2>/dev/null || true
sudo composer-cli sources add openshift-local.toml



else

    if [ ! -d "/etc/osbuild-composer/repositories/" ]
    then
        mkdir -p /etc/osbuild-composer/repositories/
    fi


    gpgkey_this=$(cat /usr/share/osbuild-composer/repositories/* | grep gpgkey | head -n 1)

cat <<EOF > additional-repos.json
{
    "${basearch}": [
        {
            "name": "rhocp",
            "baseurl": "https://cdn.redhat.com/content/dist/layered/rhel8/${basearch}/rhocp/4.10/os",
${gpgkey_this}
            "rhsm": true,
            "check_gpg": false
        },
        {
            "name": "ansible",
            "baseurl": "https://cdn.redhat.com/content/dist/layered/rhel8/${basearch}/ansible/2.9/os",
${gpgkey_this}
            "rhsm": true,
            "check_gpg": false
        }
    ]
}
EOF




 for file in $(ls /usr/share/osbuild-composer/repositories/) 
 do

 jq -s 'def deepmerge(a;b):
   reduce b[] as $item (a;
     reduce ($item | keys_unsorted[]) as $key (.;
       $item[$key] as $val | ($val | type) as $type | .[$key] = if ($type == "object") then
         deepmerge({}; [if .[$key] == null then {} else .[$key] end, $val])
       elif ($type == "array") then
         (.[$key] + $val | unique)
       else
         $val
       end)
     );
   deepmerge({}; .)' /usr/share/osbuild-composer/repositories/$file additional-repos.json > /etc/osbuild-composer/repositories/$file

 done



rm -rf additional-repos.json

fi



sudo systemctl restart osbuild-composer.service


cd  ${current_dir}