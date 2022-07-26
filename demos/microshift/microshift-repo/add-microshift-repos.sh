#!/bin/bash

echo "Starting..."
# By default use latest OCP release less 2
RHOCP_release="4.$(( $(subscription-manager repos | grep rhocp-4 | awk -F - '{print $2}' | awk -F . '{print $2}' | sort -nr | head -n1) - 2 ))"

baserelease=$(cat /etc/redhat-release  | awk '{print $6}' | awk -F . '{print $1}')
BUILD_ARCH=$(uname -i)



dnf install -y golang git rpm-build selinux-policy-devel createrepo


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



########
######## Download openshift local RPM packages (noarch for python and selinux packages)
rm -rf openshift-local 2>/dev/null || true
reposync -n -a ${BUILD_ARCH} -a noarch --download-path openshift-local \
            --repo=rhocp-${RHOCP_release}-for-rhel-${baserelease}-${BUILD_ARCH}-rpms \
            --repo=fast-datapath-for-rhel-${baserelease}-${BUILD_ARCH}-rpms >/dev/null

# Remove coreos packages to avoid conflicts
find openshift-local -name \*coreos\* -exec rm -f {} \;

# Exit if no RPM packages were found
if [ $(find openshift-local -name '*.rpm' | wc -l) -eq 0 ] ; then
    echo "No RPM packages were found at the 'rhocp rpms' repository. Exiting..."
    exit 1
fi

createrepo openshift-local >/dev/null
########



echo ""
echo "Loading sources for OpenShift and MicroShift"
echo ""

for f in openshift-local microshift-local custom-rpms ; do
    [ ! -d $f ] && continue
    cat ${f}.toml.template | sed "s;REPLACE_IMAGE_BUILDER_DIR;${ROOTDIR};g" > ${f}.toml
    sudo composer-cli sources delete $f 2>/dev/null || true
    sudo composer-cli sources add ${ROOTDIR}/_builds/${f}.toml
done



sudo systemctl restart osbuild-composer.service
