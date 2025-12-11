#!/bin/bash
set -e

echo "Updating packages..."
sudo apt-get update

echo "Installation of curl..."
sudo apt-get install -y curl

# Set permissions on kubectl
export K3S_KUBECONFIG_MODE="644"

# Installing K3s in server mode 
export INSTALL_K3S_EXEC="server --node-ip=192.168.56.110"

echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
until sudo kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    echo "  Still waiting for K3s..."
    sleep 5
done

echo "K3s is ready!"

# Wait for Traefik to be deployed and ready
echo "Waiting for Traefik..."
until sudo kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik 2>/dev/null | grep -q "Running"; do
    echo "  Still waiting for Traefik..."
    sleep 5
done

echo "Waiting for Traefik to be fully ready..."
sudo kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=180s

echo "Traefik is ready!"

# Copy kubeconfig (optional, for host access)
echo "Copy kubeconfig file..."
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo sed -i 's/127.0.0.1/192.168.56.110/g' /vagrant/k3s.yaml
sudo chmod 644 /vagrant/k3s.yaml

# Add kubectl alias
echo "alias k='kubectl'" >> /home/vagrant/.bashrc

# Deploy applications
echo "Deploying applications..."
sudo kubectl apply -f /vagrant/config/app1.yaml
sudo kubectl apply -f /vagrant/config/app2.yaml
sudo kubectl apply -f /vagrant/config/app3.yaml
sudo kubectl apply -f /vagrant/config/ingress.yaml

# Wait for apps to be ready
echo "Waiting for applications to be ready..."
sudo kubectl wait --for=condition=Ready pod -l app=app1 --timeout=120s
sudo kubectl wait --for=condition=Ready pod -l app=app2 --timeout=120s
sudo kubectl wait --for=condition=Ready pod -l app=app3 --timeout=120s

# Add hosts entries (for testing from inside the VM)
echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts

echo "================================"
echo "Installation completed!"
echo "================================"
echo ""
echo "Cluster status:"
sudo kubectl get nodes
echo ""
echo "Pods status:"
sudo kubectl get pods
echo ""
echo "Ingress status:"
sudo kubectl get ingress
echo ""
echo "Test commands (from host):"
echo "  curl -H 'Host: app1.com' http://192.168.56.110"
echo "  curl -H 'Host: app2.com' http://192.168.56.110"
echo "  curl -H 'Host: app3.com' http://192.168.56.110"
echo "  curl http://192.168.56.110  # Should show app3"
