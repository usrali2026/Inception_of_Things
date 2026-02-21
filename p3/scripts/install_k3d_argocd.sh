#!/usr/bin/env bash
set -euo pipefail

# Re-exec under docker group if not already in it
if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    exec sg docker "$0" "$@"
fi

echo "[P3] Installing dependencies (Docker, kubectl, k3d)..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates docker.io
sudo systemctl enable --now docker

# Install kubectl
if ! command -v kubectl >/dev/null 2>&1; then
    echo "[P3] Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi
kubectl version --client

# Install k3d
if ! command -v k3d >/dev/null 2>&1; then
    echo "[P3] Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Create K3d cluster
CLUSTER_NAME="iot-p3"
if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${CLUSTER_NAME}"; then
    echo "[P3] Cluster '${CLUSTER_NAME}' already exists, skipping"
else
    echo "[P3] Creating k3d cluster '${CLUSTER_NAME}'..."
    k3d cluster create "${CLUSTER_NAME}" --servers 1 --agents 1
fi

kubectl config use-context "k3d-${CLUSTER_NAME}"

# Create namespaces
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl get ns dev    >/dev/null 2>&1 || kubectl create namespace dev

# Install Argo CD
echo "[P3] Installing Argo CD..."
kubectl apply -n argocd \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for all key Argo CD deployments (evalsheet checks 7 pods)
echo "[P3] Waiting for all Argo CD deployments to be ready..."
for deploy in argocd-server argocd-repo-server \
              argocd-applicationset-controller \
              argocd-notifications-controller; do
    kubectl -n argocd wait --for=condition=Available \
        deploy/$deploy --timeout=600s
done

# Apply Argo CD Application manifest
APP_MANIFEST="${PROJECT_ROOT}/confs/argocd-app.yaml"
echo "[P3] Applying Argo CD Application: ${APP_MANIFEST}"
kubectl apply -f "${APP_MANIFEST}"

# Start ArgoCD UI port-forward in background
pkill -f "port-forward.*argocd-server" 2>/dev/null || true
kubectl -n argocd port-forward svc/argocd-server 8080:443 >/dev/null 2>&1 &

# Print credentials
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d)

echo ""
echo "[P3] ✓ Setup complete!"
echo "[P3] ArgoCD UI → https://localhost:8080"
echo "[P3] Username  → admin"
echo "[P3] Password  → ${ARGOCD_PASS}"
echo "[P3] Dev pod   → kubectl get pods -n dev"
