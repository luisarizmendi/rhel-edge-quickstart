#!/bin/bash

# Using upstream will take less time since you are using already built RPMs from Fedora..
upstream="false"


echo "Starting..."
# By default use latest OCP release less 2
RHOCP_release="4.$(( $(subscription-manager repos | grep rhocp-4 | awk -F - '{print $2}' | awk -F . '{print $2}' | sort -nr | head -n1) - 2 ))"


baserelease=$(cat /etc/redhat-release  | awk '{print $6}' | awk -F . '{print $1}')
basearch=$(arch)




###### MICROSHIFT REPO

if [ $upstream = false ]
then

    dnf install -y golang git rpm-build selinux-policy-devel createrepo yum-utils


    git clone https://github.com/openshift/microshift

    cd microshift

    git pull

    ROOTDIR=$(git rev-parse --show-toplevel)/scripts/image-builder

    make 

    make rpm
    make srpm

    cd ..



    ########
    ######## Copy MicroShift RPM packages
    rm -rf microshift-local 2>/dev/null || true
    cp -TR microshift/packaging/rpm/_rpmbuild/RPMS microshift-local
    createrepo microshift-local >/dev/null
    ########



cat <<EOF > microshift-repo.toml
id = "microshift-local"
name = "MicroShift Local Repo"
type = "yum-baseurl"
url = "file://$(pwd)/microshift/scripts/image-builder/_builds/microshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF


else 

cat <<EOF > microshift-repo.toml
id = "microshift"
name = "MicroShift"
type = "yum-baseurl"
url = "https://download.copr.fedorainfracloud.org/results/@redhat-et/microshift/epel-${baserelease}-${basearch}/"
check_gpg = false
check_ssl = false
system = false
EOF


fi 



sudo composer-cli sources delete microshift 2>/dev/null || true
sudo composer-cli sources add microshift-repo.toml






###### OPENSHIFT REPO

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

cat <<EOF > openshift-repo.toml
id = "openshift"
name = "OpenShift Repo"
type = "yum-baseurl"
url = "file://$(pwd)/microshift/scripts/image-builder/_builds/openshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF





sudo composer-cli sources delete openshift 2>/dev/null || true
sudo composer-cli sources add openshift-repo.toml







sudo systemctl restart osbuild-composer.service
