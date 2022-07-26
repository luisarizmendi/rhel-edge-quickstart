#!/bin/bash

echo "Starting..."
# By default use latest OCP release less 2
RHOCP_release="4.$(( $(subscription-manager repos | grep rhocp-4 | awk -F - '{print $2}' | awk -F . '{print $2}' | sort -nr | head -n1) - 2 ))"


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
    cp -TR microshift/packaging/rpm/_rpmbuild/RPMS microshift-local
    createrepo microshift-local >/dev/null
    ########



cat <<EOF > microshift-repo.toml
id = "microshift"
name = "MicroShift Repo"
type = "yum-baseurl"
url = "file://${current_dir}/microshift/scripts/image-builder/_builds/microshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF




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
url = "file://${current_dir}/microshift/scripts/image-builder/_builds/openshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF





sudo composer-cli sources delete openshift 2>/dev/null || true
sudo composer-cli sources add openshift-repo.toml







sudo systemctl restart osbuild-composer.service


cd  ${current_dir}