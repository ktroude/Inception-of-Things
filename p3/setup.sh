#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo "=================================================================="
echo "IOT - PART 3: K3D + ARGOCD SETUP"
echo "=================================================================="

# =====================================
# PHASE 1: INSTALL REQUIRED TOOLS
# =====================================
log_info "Phase 1: Installing required tools..."

# Update system
sudo apt-get update -qq

# Install base tools
sudo apt-get install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release jq

# Docker
if ! command -v docker &> /dev/null; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    log_warning "Docker installed - You may need to re-login for group permissions"
else
    log_success "Docker already installed"
fi

# kubectl
if ! command -v kubectl &> /dev/null; then
    log_info "Installing kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    log_success "kubectl installed"
else
    log_success "kubectl already installed"
fi

# k3d
if ! command -v k3d &> /dev/null; then
    log_info "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    log_success "k3d installed"
else
    log_success "k3d already installed"
fi

log_success "Phase 1 completed: All tools installed"
echo ""

# =====================================
# PHASE 2: CREATE K3D CLUSTER
# =====================================
log_info "Phase 2: Creating K3d cluster..."

# Delete existing cluster if present
k3d cluster delete iot-cluster 2>/dev/null || true

# Create cluster with NodePort range for services
k3d cluster create iot-cluster \
  --api-port 6550 \
  --port "8888:30888@server:0" \
  --agents 1

# Wait for nodes to be ready
log_info "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

log_success "Phase 2 completed: Cluster is ready"
kubectl get nodes
echo ""

# =====================================
# PHASE 3: CREATE NAMESPACES
# =====================================
log_info "Phase 3: Creating namespaces..."

kubectl create namespace argocd
kubectl create namespace dev

log_success "Namespaces created:"
kubectl get namespaces | grep -E "NAME|argocd|dev"
echo ""

# =====================================
# PHASE 4: INSTALL ARGOCD
# =====================================
log_info "Phase 4: Installing ArgoCD..."

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log_info "Waiting for ArgoCD pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=600s

log_success "ArgoCD installed successfully"
echo ""

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# =====================================
# PHASE 5: DEPLOY APPLICATION VIA ARGOCD
# =====================================
log_info "Phase 5: Deploying application via ArgoCD..."

# Apply ArgoCD Application from local config
kubectl apply -f confs/application.yaml

log_info "Waiting for application to sync..."
sleep 15

# Wait for app pods
log_info "Waiting for application pods in dev namespace..."
kubectl wait --for=condition=Ready pods --all -n dev --timeout=120s 2>/dev/null || log_warning "Timeout waiting for pods (they may still be starting)"

log_success "Application deployment initiated"
echo ""

# =====================================
# VERIFICATION & INFO
# =====================================
echo "=================================================================="
echo "SETUP COMPLETED SUCCESSFULLY"
echo "=================================================================="
echo ""

log_success "Cluster info:"
kubectl cluster-info | head -1
echo ""

log_success "Namespaces:"
kubectl get ns | grep -E "NAME|argocd|dev"
echo ""

log_success "ArgoCD Applications:"
kubectl get applications -n argocd
echo ""

log_success "Pods in dev namespace:"
kubectl get pods -n dev
echo ""

echo "=================================================================="
echo "ACCESS INFORMATION"
echo "=================================================================="
echo ""
echo -e "${GREEN}ArgoCD Web UI:${NC}"
echo "  Command: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  URL:     https://localhost:8080"
echo "  Login:   admin"
echo "  Pass:    $ARGOCD_PASSWORD"
echo ""
echo -e "${GREEN}Application Access:${NC}"
echo "  Command: kubectl port-forward -n dev svc/wil-playground-service 8888:8888"
echo "  Test:    curl http://localhost:8888"
echo "  Expected: {\"status\":\"ok\", \"message\": \"v1\"}"
echo ""
echo -e "${YELLOW}To update application version:${NC}"
echo "  1. Edit: app/deployment.yaml in GitHub repo"
echo "  2. Change: wil42/playground:v1 → wil42/playground:v2"
echo "  3. Git: commit and push"
echo "  4. ArgoCD will auto-sync within seconds"
echo ""
log_success "Setup complete! Follow instructions above to access services."
