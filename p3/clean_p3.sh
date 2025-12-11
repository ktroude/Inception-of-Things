#!/bin/bash

set -e

echo "=== Cleaning P3 ==="

# Delete K3d cluster
echo "Deleting k3d cluster (iot-cluster)..."
k3d cluster delete iot-cluster 2>/dev/null || echo "Cluster already deleted"

# Clean docker containers created by K3d
echo "Cleaning leftover Docker containers..."
docker ps -a | grep k3d- >/dev/null 2>&1 && \
    docker rm -f $(docker ps -aq --filter "name=k3d-") 2>/dev/null || \
    echo "No leftover k3d containers"

# Clean docker volumes created by K3d
echo "Cleaning docker volumes created by K3d..."
docker volume ls | grep k3d- >/dev/null 2>&1 && \
    docker volume rm $(docker volume ls -q --filter "name=k3d-") 2>/dev/null || \
    echo "No leftover k3d volumes"

# Clear kubeconfig entries
echo "Cleaning kubeconfig entries..."

# Remove old K3d contexts from ~/.kube/config
kubectl config delete-cluster k3d-iot-cluster 2>/dev/null || true
kubectl config delete-user k3d-iot-cluster 2>/dev/null || true
kubectl config delete-context k3d-iot-cluster 2>/dev/null || true

echo "Kubeconfig cleaned"

# Optional Cleanup (uncomment if needed)
# echo "Removing dangling Docker images..."
# docker image prune -f

# echo "Removing ALL unused Docker objects..."
# docker system prune -af

echo "=== Cleanup P3 complete! ==="
