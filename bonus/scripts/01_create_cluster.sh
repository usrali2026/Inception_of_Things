#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[01_create_cluster] $*"
}

CLUSTER_NAME="iot-bonus"

log "Creating k3d cluster '${CLUSTER_NAME}' (if it does not already exist)"

if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
  log "Cluster ${CLUSTER_NAME} already exists, skipping creation"
else
  # Map host VM ports 80/443 to k3d loadbalancer for ingress.
  k3d cluster create "${CLUSTER_NAME}" \
    --agents 1 \
    --servers 1 \
    --port "80:80@loadbalancer" \
    --port "443:443@loadbalancer"
  log "Cluster ${CLUSTER_NAME} created"
fi

# Ensure kubectl points to this cluster
log "Using kubeconfig:"
k3d kubeconfig get "${CLUSTER_NAME}" > /tmp/kubeconfig-"${CLUSTER_NAME}"
export KUBECONFIG=/tmp/kubeconfig-"${CLUSTER_NAME}"
log "KUBECONFIG set to ${KUBECONFIG}"

kubectl get nodes
