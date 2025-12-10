#!/bin/bash

set -e

echo "Cleaning up K3d cluster..."

# Tuer les port-forwards
pkill -f "kubectl port-forward" 2>/dev/null || true

# Supprimer le cluster
k3d cluster delete iot-cluster 2>/dev/null || true

echo "✓ Cleanup complete"
echo "Run ./setup.sh to recreate the cluster"
