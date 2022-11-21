#!/bin/bash


####### k8s clients
#######
curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xvf openshift-client-linux.tar.gz
chmod +x oc 
cp oc /var/usrlocal/bin/
chmod +x kubectl 
cp kubectl /var/usrlocal/bin/

mkdir ~/.kube
cp /var/lib/microshift/resources/kubeadmin/kubeconfig ~/.kube/config


####### firewalld
#######
# Mandatory settings
sudo firewall-cmd --permanent --zone=trusted --add-source=10.85.0.0/16 
sudo firewall-cmd --permanent --zone=trusted --add-source=169.254.169.1
sudo firewall-cmd --reload
# Optional settings
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --permanent --zone=public --add-port=443/tcp
sudo firewall-cmd --permanent --zone=public --add-port=5353/udp
sudo firewall-cmd --permanent --zone=public --add-port=30000-32767/tcp
sudo firewall-cmd --permanent --zone=public --add-port=30000-32767/udp
sudo firewall-cmd --permanent --zone=public --add-port=6443/tcp
sudo firewall-cmd --reload








cat <<EOF > /etc/microshift/config.yaml
# Directory for storing audit logs
#auditLogDir: ""

# Cluster settings
cluster:

  # IP range for use by the cluster
  #clusterCIDR: 10.42.0.0/16

  # DNS server IP is the k8s service IP address which pods query for name resolution
  #dns: 10.43.0.10

  # Base DNS domain used to construct fully qualified pod and service domain names
  #domain: cluster.local

  # IP range for services in the cluster
  #serviceCIDR: 10.43.0.0/16

  # Node ports allowed for services
  #serviceNodePortRange: 30000-32767

  # URL of the API server for the cluster
  #url: https://127.0.0.1:6443

  # MTU for CNI
  #mtu: "1400"

# Location for data created by MicroShift
#dataDir: /var/lib/microshift

# Log verbosity (0-5)
#logVLevel: 0

# Locations to scan for manifests to load on startup
#manifests:
#- /usr/lib/microshift/manifests
#- /etc/microshift/manifests

# The IP of the node (defaults to IP of default route)
#nodeIP: ""

# The name of the node (defaults to hostname)
#nodeName: "$(hostname)"
EOF








#sed 's|"cniVersion": .*|"cniVersion": "0.4.0"|' /etc/cni/net.d/100-crio-bridge.conf






systemctl restart crio

systemctl restart microshift















