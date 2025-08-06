#!/bin/bash

set -e

# 1 Install ArgoCD in the argocd namespace
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2 Wait for all ArgoCD pods to be ready
echo "Waiting for all ArgoCD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=400s

# 3 Check ArgoCD pods
kubectl get pods -n argocd

# 4 Obtain initial ArgoCD password
echo ""
echo "Initial ArgoCD password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""log_warning

# 5 Configuring access to the ArgoCD interface
echo "To access the ArgoCD interface:"
echo "1. In a terminal: kubectl port-forward svc/argocd-server -n argocd 8081:443"
echo "2. Open web page: https://localhost:8081"
echo "3. Login: admin"
echo "4. Password: [the one displayed above]"

# 6. Expose ArgoCD via Ingress
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    spec.ingressClassName: traefik
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF