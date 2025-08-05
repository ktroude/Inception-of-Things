#!/bin/bash

set -e

git clone https://github.com/ktroude/iot-argocd
cd iot-argocd
kubectl apply -f argocd/application.yaml