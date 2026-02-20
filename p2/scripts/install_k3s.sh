#!/usr/bin/env bash
set -euo pipefail

log() { echo "[P2] $*"; }

# Re-run as root if needed (Vagrant often runs as root, but make it robust)
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  exec sudo -E bash "$0" "$@"
fi

IP="${SERVER_IP:-192.168.56.110}"
MANIFEST="/vagrant/confs/apps-ingress.yaml"
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
export KUBECONFIG="$KUBECONFIG_PATH"

retry() {
  local tries="$1"; shift
  local delay="$1"; shift
  local n=1
  until "$@"; do
    if [ "$n" -ge "$tries" ]; then
      return 1
    fi
    sleep "$delay"
    n=$((n+1))
  done
}

log "Starting K3s server setup..."
log "Using IP=${IP}"

log "Installing prerequisites..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl ca-certificates

install_k3s() {
  log "Installing k3s server..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --write-kubeconfig-mode=644 \
    --node-ip=${IP} \
    --advertise-address=${IP} \
    --tls-san=${IP}" sh -
}

# Install or ensure k3s is running
if command -v k3s >/dev/null 2>&1 && systemctl list-unit-files | grep -q '^k3s\.service'; then
  log "k3s already installed, ensuring it's running"
  systemctl enable --now k3s
else
  install_k3s
fi

# Ensure kubectl exists (k3s usually does this, but keep it explicit)
if [ ! -x /usr/local/bin/kubectl ] && [ -x /usr/local/bin/k3s ]; then
  ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
fi

log "Waiting for kubeconfig to exist..."
retry 180 1 test -f "$KUBECONFIG_PATH"
retry 60 1 test -s "$KUBECONFIG_PATH"

log "Waiting for Kubernetes API to be ready (/readyz)..."
# /readyz is the canonical apiserver readiness endpoint. [web:54]
retry 180 2 kubectl get --raw='/readyz' >/dev/null 2>&1

log "Waiting for node object to exist..."
retry 180 2 bash -c 'kubectl get nodes --no-headers 2>/dev/null | grep -q .'

log "Waiting for node Ready..."
kubectl wait --for=condition=Ready node --all --timeout=300s

# Ensure Traefik is installed/ready (K3s installs Traefik asynchronously)
log "Waiting for traefik deployment to exist..."
retry 180 2 kubectl -n kube-system get deploy traefik >/dev/null 2>&1

log "Waiting for traefik to be Available..."
kubectl -n kube-system wait --for=condition=Available deploy/traefik --timeout=300s

# Create namespace declaratively (idempotent; avoids imperative-race patterns)
log "Ensuring namespace webapps exists..."
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: webapps
EOF

log "Applying manifests: ${MANIFEST}"
test -f "$MANIFEST"
kubectl apply -f "$MANIFEST"

# Wait for your deployments (app1/app2/app3)
log "Waiting for webapps deployments to be Available..."
retry 120 2 bash -c 'kubectl -n webapps get deploy --no-headers 2>/dev/null | grep -q .'
kubectl -n webapps wait --for=condition=Available deploy --all --timeout=300s

# Wait for pods to be Ready
log "Waiting for webapps pods to be Ready..."
retry 120 2 bash -c 'kubectl -n webapps get pods --no-headers 2>/dev/null | grep -q .'
kubectl -n webapps wait --for=condition=Ready pod --all --timeout=300s

log "Setup complete."

