#!/bin/bash

# hostname
export HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
sudo hostnamectl set-hostname $HOSTNAME


#k3s agent
sudo curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${MASTER_TOKEN} INSTALL_K3S_VERSION=${K3S_VERSION} sh -s - agent \
    --node-name="$(hostname -f)" \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
    --node-label="role=worker" 
