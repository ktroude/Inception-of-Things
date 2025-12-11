#!/bin/bash

# Stop on errors
set -e

# Update packages
sudo apt-get update --fix-missing
sudo apt-get install -y curl

# Define k3s permissions and mode
export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC="server --node-ip=192.168.56.110"

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait until the token is available
TOKEN="/var/lib/rancher/k3s/server/node-token"
while [ ! -f "$TOKEN" ]; do
    sleep 2
done

# Copy token in a shared folder for worker nodes
sudo cp $TOKEN /vagrant/token

# Copy kubeconfig to shared folder
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
sudo cp $KUBECONFIG /vagrant/k3s.yaml
sudo chmod 644 /vagrant/k3s.yaml

echo "alias k='kubectl'" >> /home/vagrant/.bashrc
