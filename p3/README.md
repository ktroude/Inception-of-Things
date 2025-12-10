# IOT - Part 3: K3D + ArgoCD

## Prerequisites

- Ubuntu/Debian Linux
- sudo access
- Internet connection

## Quick Start
```bash
# Make script executable
chmod +x setup.sh

# Run setup (installs everything)
./setup.sh
```

## What does setup.sh do?

1. Installs Docker, kubectl, k3d
2. Creates K3d cluster "iot-cluster"
3. Creates namespaces: argocd, dev
4. Installs ArgoCD
5. Deploys application from GitHub via ArgoCD

## Access ArgoCD Web UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open: https://localhost:8080
- User: admin
- Password: (shown at end of setup.sh)

## Access Application
```bash
kubectl port-forward -n dev svc/wil-playground-service 8888:8888
curl http://localhost:8888
```

Expected output: `{"status":"ok", "message": "v1"}`

## Update Application Version

1. Edit `app/deployment.yaml` in GitHub repo
2. Change image tag: `wil42/playground:v1` → `wil42/playground:v2`
3. Commit and push
4. ArgoCD auto-syncs within seconds
5. Test again: `curl http://localhost:8888` → should show v2

## Verify Deployment
```bash
# Check namespaces
kubectl get ns

# Check ArgoCD
kubectl get pods -n argocd
kubectl get applications -n argocd

# Check application
kubectl get pods -n dev
kubectl get svc -n dev

# Describe ArgoCD application
kubectl describe application ktroude-playground-app -n argocd
```

## Cleanup
```bash
k3d cluster delete iot-cluster
```

## Troubleshooting

**If pods don't start:**
```bash
kubectl logs -n dev <pod-name>
kubectl describe pod -n dev <pod-name>
```

**If ArgoCD doesn't sync:**
```bash
kubectl describe application ktroude-playground-app -n argocd
```

**Reset everything:**
```bash
k3d cluster delete iot-cluster
./setup.sh
```
```

---

## Repository GitHub : `ktroude/iot-argocd`

### Structure
```
iot-argocd/
├── README.md
└── app/
    └── deployment.yaml
