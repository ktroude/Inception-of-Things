#!/bin/bash

set -e

# Colors for logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if command -v $1 &> /dev/null; then
        log_success "$1 is already installed ($(command -v $1))"
        return 0
    else
        log_warning "$1 is not installed"
        return 1
    fi
}

echo "=================================================================="
echo "INSTALLING K3D + ARGOCD"
echo "=================================================================="

# OS verification
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "This script is designed for Linux (Ubuntu/Debian)"
    exit 1
fi

log_info "Detected system: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Linux")"

### 1 SYSTEM UPDATE
log_info "Updating system packages..."
sudo apt-get update -qq

log_info "Installing base tools..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    apt-transport-https \ 
    ca-certificates \
    gnupg \
    lsb-release \
    jq

### 2 DOCKER INSTALLATION
log_info "Checking Docker..."

if check_command docker; then
    # Check if Docker is working
    if sudo docker ps &> /dev/null; then
        log_success "Docker is working correctly"
    else
        log_warning "Docker is installed but not working, restarting service..."
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
else
    log_info "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully"
    log_warning "IMPORTANT: Restart your session or run 'newgrp docker' to use Docker without sudo"
fi

### 3 KUBECTL INSTALLATION
log_info "Checking kubectl..."

if check_command kubectl; then
    log_success "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
else
    log_info "Installing kubectl..."
    
    # Download kubectl
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    
    # Install kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    log_success "kubectl installed: version $KUBECTL_VERSION"
fi

### 4 K3D INSTALLATION
log_info "Checking k3d..."

if check_command k3d; then
    log_success "k3d version: $(k3d version | head -1)"
else
    log_info "Installing k3d..."
    
    # Install k3d
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    
    log_success "k3d installed successfully"
fi

### 5 FINAL CHECKS
echo ""
log_info "Running final checks..."

# Test Docker (with or without sudo depending on permissions)
if docker ps &> /dev/null || sudo docker ps &> /dev/null; then
    log_success "Docker is working"
else
    log_error "Docker is not working"
fi

# Test kubectl
if kubectl version --client &> /dev/null; then
    log_success "kubectl is working"
elsecurl -LO "https://dl.
    log_error "kubectl is not working"
fi

# Test k3d
if k3d version &> /dev/null; then
    log_success "k3d is working"
else
    log_error "k3d is not working"
fi

echo ""
echo "=================================================================="
echo "INSTALLATION COMPLETED"
echo "=================================================================="
