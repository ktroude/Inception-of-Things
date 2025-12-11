#!/bin/bash

# Stop on errors
set -e

# Update packages
sudo apt-get update --fix-missing
sudo apt-get install -y curl

# Retrieve server IP and token file
SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/token"

# Wait until the token file is available
while [ ! -f "$TOKEN_FILE" ]; do
    sleep 2
done

# Read the token
NODE_TOKEN=$(cat $TOKEN_FILE)

# Install k3s agent
export INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111"
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${NODE_TOKEN}"  sh -

echo "alias k='kubectl'" >> /home/vagrant/.bashrc

