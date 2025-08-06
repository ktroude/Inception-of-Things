#!/bin/bash

set -e

# 1 Check that everything is installed
docker --version
kubectl version --client
k3d version

# 2 Create a K3d cluster with port mapping
k3d cluster create iot-cluster \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --agents 1

# 3 Check that the cluster is running
kubectl get nodes
kubectl cluster-info

# 4 Create the required namespaces
kubectl create namespace argocd
kubectl create namespace dev

# 5 Check namespaces
kubectl get namespaces

