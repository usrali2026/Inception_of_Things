#!/bin/bash
set -e

echo "=============================="
echo " [1/4] Creating K3d cluster"
echo "=============================="
k3d cluster create iot-cluster \
  --port "8080:80@loadbalancer" \
  --port "8888:30888@loadbalancer"

sleep 20
kubectl get nodes

echo "=============================="
echo " [2/4] Installing ArgoCD"
echo "=============================="
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=============================="
echo " [3/4] Creating dev namespace"
echo "=============================="
kubectl create namespace dev

echo "Waiting for ArgoCD (2-3 min)..."
kubectl wait --for=condition=available \
  --timeout=300s deployment/argocd-server -n argocd

echo "=============================="
echo " [4/4] Deploying ArgoCD Application"
echo "=============================="
kubectl apply -f ~/IoT/p3/confs/application.yaml

echo ""
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo ""
echo ""
echo "Access ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then: https://localhost:8080  (user: admin)"
