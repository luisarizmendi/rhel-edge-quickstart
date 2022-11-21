#!/bin/bash

branch="main"


baserelease=$(cat /etc/redhat-release  | awk '{print $6}' | awk -F . '{print $1}')
basearch=$(arch)

current_dir="$(pwd)"
target_dir="/custom-repos"

rm -rf ${target_dir} 2>/dev/null || true
mkdir -p ${target_dir}
chmod -R 777 ${target_dir}



# Added because some dependencies
#sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

dnf update -y



###### MICROSHIFT REPO

    dnf install -y golang git rpm-build selinux-policy-devel createrepo yum-utils


    git clone -b ${branch}  https://github.com/openshift/microshift

    cd microshift

    git pull


echo ""
echo "This will take some time..."
echo ""


    make 

    make rpm

    make srpm


echo ""
echo "RPMs generated:"

find _output -name \*.rpm


echo ""


    ########
    ######## Copy MicroShift RPM packages
    rm -rf ${current_dir}/microshift/scripts/image-builder/_builds/microshift-local 2>/dev/null || true
    cp -TR ${current_dir}/microshift/_output/rpmbuild ${target_dir}/microshift-local
    createrepo ${target_dir}/microshift-local/ >/dev/null
    chmod -R 777 ${target_dir}/microshift-local
    
    ########



cat <<EOF > microshift-local.toml
id = "microshift-local"
name = "MicroShift Local Repo"
type = "yum-baseurl"
url = "file://${target_dir}/microshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF




sudo composer-cli sources delete microshift-local 2>/dev/null || true
sudo composer-cli sources add microshift-local.toml






###### OPENSHIFT REPO


#subscription-manager repos | grep rhocp-4
#if [ $? = 0 ]
#then

    # By default use latest OCP release less 1
    RHOCP_release="4.$(( $(subscription-manager repos | grep rhocp-4 | awk -F - '{print $2}' | awk -F . '{print $2}' | sort -nr | head -n1) - 1 ))"

    ########
    ######## Download openshift local RPM packages (noarch for python and selinux packages)
    rm -rf ${target_dir}/openshift-local 2>/dev/null || true
    mkdir -p ${target_dir}/openshift-local
    reposync -n -a ${basearch} -a noarch --download-path ${target_dir}/openshift-local \
                --repo=rhocp-${RHOCP_release}-for-rhel-${baserelease}-${basearch}-rpms \
                --repo=fast-datapath-for-rhel-${baserelease}-${basearch}-rpms >/dev/null

    # Remove coreos packages to avoid conflicts
    find ${target_dir}/openshift-local -name \*coreos\* -exec rm -f {} \;

    # Exit if no RPM packages were found
    if [ $(find ${target_dir}/openshift-local -name '*.rpm' | wc -l) -eq 0 ] ; then
        echo "No RPM packages were found at the 'rhocp rpms' repository. Exiting..."
        exit 1
    fi

    createrepo ${target_dir}/openshift-local >/dev/null
    ########

cat <<EOF > openshift-local.toml
id = "openshift-local"
name = "OpenShift Local Repo"
type = "yum-baseurl"
url = "file://${target_dir}/openshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF


sudo composer-cli sources delete openshift-local 2>/dev/null || true
sudo composer-cli sources add openshift-local.toml



#else

#    if [ ! -d "/etc/osbuild-composer/repositories/" ]
#    then
#        mkdir -p /etc/osbuild-composer/repositories/
#    fi


#    gpgkey_this=$(cat /usr/share/osbuild-composer/repositories/* | grep gpgkey | head -n 1)

#cat <<EOF > additional-repos.json
#{
#    "${basearch}": [
#        {
#            "name": "rhocp",
#            "baseurl": "https://cdn.redhat.com/content/dist/layered/rhel8/${basearch}/rhocp/4.10/os",
#${gpgkey_this}
#            "rhsm": true,
#            "check_gpg": false
#        },
#        {
#            "name": "ansible",
#            "baseurl": "https://cdn.redhat.com/content/dist/layered/rhel8/${basearch}/ansible/2.9/os",
#${gpgkey_this}
#            "rhsm": true,
#            "check_gpg": false
#        }
#    ]
#}
#EOF




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



#rm -rf additional-repos.json

#fi



sudo systemctl restart osbuild-composer.service


cd  ${current_dir}