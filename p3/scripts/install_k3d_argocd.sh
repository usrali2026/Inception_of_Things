#!/usr/bin/env bash
set -euo pipefail

echo "[P3] Installing dependencies (Docker, kubectl, k3d)..."

# Script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Update package list
sudo apt-get update -y

# Install Docker and curl/ca-certificates
sudo apt-get install -y curl ca-certificates docker.io
sudo systemctl enable --now docker

# Install kubectl manually (bypass broken apt repo)
if ! command -v kubectl >/dev/null 2>&1; then
    echo "[P3] Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi
kubectl version --client

# Install k3d if missing
if ! command -v k3d >/dev/null 2>&1; then
    echo "[P3] Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Cluster setup
CLUSTER_NAME="iot-p3"

if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${CLUSTER_NAME}"; then
    echo "[P3] k3d cluster '${CLUSTER_NAME}' already exists, skipping create"
else
    echo "[P3] Creating k3d cluster '${CLUSTER_NAME}'..."
    k3d cluster create "${CLUSTER_NAME}" --servers 1 --agents 1
fi

echo "[P3] Using kube-context k3d-${CLUSTER_NAME}"
kubectl config use-context "k3d-${CLUSTER_NAME}"

# Create required namespaces
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl get ns dev >/dev/null 2>&1 || kubectl create namespace dev

# Install Argo CD
echo "[P3] Installing Argo CD in namespace argocd..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[P3] Waiting for Argo CD server deployment to be Available..."
kubectl -n argocd wait --for=condition=Available deploy/argocd-server --timeout=600s

# Apply Argo CD Application manifest
APP_MANIFEST="${PROJECT_ROOT}/confs/argocd-app.yaml"
echo "[P3] Applying Argo CD Application: ${APP_MANIFEST}"
kubectl apply -f "${APP_MANIFEST}"

echo "[P3] Done."
echo "[P3] Tip: get Argo CD initial password:"
echo "      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "[P3] Tip: open Argo CD UI with port-forward:"
echo "      kubectl -n argocd port-forward svc/argocd-server 8080:443"

