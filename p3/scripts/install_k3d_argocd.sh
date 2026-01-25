#!/usr/bin/env bash
set -euo pipefail

echo "[P3] Installing dependencies (Docker, k3d, kubectl, Argo CD)..."

# Detect directory of this script and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Basic tools ---
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates docker.io gnupg lsb-release

# Ensure Docker is running
sudo systemctl enable --now docker

# --- Install kubectl (from Ubuntu repos is fine for local lab) ---
if ! command -v kubectl >/dev/null 2>&1; then
  echo "[P3] Installing kubectl..."
  # sudo apt-get install -y kubectl
fi

# --- Install k3d ---
if ! command -v k3d >/dev/null 2>&1; then
  echo "[P3] Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# --- Create k3d cluster if needed ---
CLUSTER_NAME="iot-p3"

if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${CLUSTER_NAME}"; then
  echo "[P3] k3d cluster '${CLUSTER_NAME}' already exists, skipping create"
else
  echo "[P3] Creating k3d cluster '${CLUSTER_NAME}'..."
  k3d cluster create "${CLUSTER_NAME}" --servers 1 --agents 1
fi

# Use this cluster context
echo "[P3] Setting current kube-context to k3d-${CLUSTER_NAME}"
kubectl config use-context "k3d-${CLUSTER_NAME}"

# --- Namespaces ---
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl get ns dev >/dev/null 2>&1 || kubectl create namespace dev

# --- Install Argo CD into argocd namespace ---
# Official install manifest
echo "[P3] Installing Argo CD in namespace 'argocd'..."
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD server to be up
echo "[P3] Waiting for Argo CD server pod to be Ready..."
for i in {1..60}; do
  if kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server 2>/dev/null \
      | grep -q " 1/1 *Running"; then
    echo "[P3] Argo CD server is Ready."
    break
  fi
  sleep 5
done

# --- Create Argo CD Application that points to your GitHub repo ---
APP_MANIFEST="${PROJECT_ROOT}/confs/argocd-app.yaml"

if [ ! -f "${APP_MANIFEST}" ]; then
  echo "[P3][ERROR] Application manifest not found at ${APP_MANIFEST}"
  exit 1
fi

echo "[P3] Applying Argo CD Application from ${APP_MANIFEST}..."
kubectl apply -f "${APP_MANIFEST}"

echo "[P3] Setup complete. Argo CD should now sync the app into namespace 'dev'."
