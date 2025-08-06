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

echo "=================================================================="
echo "CLEANING UP ALL K3D RESOURCES"
echo "=================================================================="

### 1 STOP ANY RUNNING PORT-FORWARDS
log_info "Stopping any running kubectl port-forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true
log_success "Port-forwards stopped"

### 2 DELETE ALL K3D CLUSTERS
log_info "Listing existing K3d clusters..."
k3d cluster list

log_info "Deleting all K3d clusters..."
if k3d cluster list --no-headers 2>/dev/null | grep -q .; then
    for cluster in $(k3d cluster list --no-headers | awk '{print $1}'); do
        log_warning "Deleting cluster: $cluster"
        k3d cluster delete $cluster
    done
    log_success "All K3d clusters deleted"
else
    log_info "No K3d clusters found to delete"
fi

### 3 CLEAN KUBECTL CONTEXTS
log_info "Cleaning kubectl contexts..."

# Delete k3d-related contexts
kubectl config get-contexts --no-headers 2>/dev/null | grep "k3d-" | awk '{print $1}' | while read context; do
    log_warning "Deleting context: $context"
    kubectl config delete-context $context 2>/dev/null || true
done

# Delete k3d-related clusters from kubeconfig
kubectl config get-clusters --no-headers 2>/dev/null | grep "k3d-" | while read cluster; do
    log_warning "Deleting cluster config: $cluster"
    kubectl config delete-cluster $cluster 2>/dev/null || true
done

# Delete k3d-related users from kubeconfig
kubectl config get-users --no-headers 2>/dev/null | grep "k3d-" | while read user; do
    log_warning "Deleting user config: $user"
    kubectl config delete-user $user 2>/dev/null || true
done

log_success "Kubectl contexts cleaned"

### 4 CLEAN DOCKER CONTAINERS
log_info "Cleaning Docker containers related to k3d..."

# Stop and remove k3d containers
docker ps -a --filter "label=app=k3d" --format "{{.ID}}" | while read container; do
    if [ -n "$container" ]; then
        log_warning "Stopping and removing container: $container"
        docker stop $container 2>/dev/null || true
        docker rm $container 2>/dev/null || true
    fi
done

# Clean k3d networks
docker network ls --filter "label=app=k3d" --format "{{.ID}}" | while read network; do
    if [ -n "$network" ]; then
        log_warning "Removing network: $network"
        docker network rm $network 2>/dev/null || true
    fi
done

# Clean k3d volumes
docker volume ls --filter "label=app=k3d" --format "{{.Name}}" | while read volume; do
    if [ -n "$volume" ]; then
        log_warning "Removing volume: $volume"
        docker volume rm $volume 2>/dev/null || true
    fi
done

log_success "Docker resources cleaned"

### 5 CLEAN DOCKER SYSTEM
log_info "Cleaning unused Docker resources..."
docker system prune -f --volumes 2>/dev/null || true
log_success "Docker system cleaned"

### 6 RESET KUBECTL CONFIG 
log_info "Checking kubectl configuration..."

# If no valid context remains, create a minimal config
if ! kubectl config current-context &>/dev/null; then
    log_warning "No valid kubectl context found"
    log_info "kubectl will be reconfigured when you create a new cluster"
fi

### 7 REMOVE PROJECT
log_info "Remove iot-argocd project"
rm -rf ./iot-argocd
log_success "iot-argocd project removed"

echo ""
echo "=================================================================="
echo "CLEANUP COMPLETED"
echo "=================================================================="
