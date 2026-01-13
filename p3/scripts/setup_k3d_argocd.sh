#!/usr/bin/env bash
set -e

CLUSTER_NAME="k3d-iot"
ARGO_NS="argocd"
DEV_NS="dev"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../.."

# Create k3d cluster if not exists
if ! k3d cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Creating k3d cluster ${CLUSTER_NAME}..."
  k3d cluster create "${CLUSTER_NAME}" \
    --servers 1 \
    --agents 1 \
    --port "8888:80@loadbalancer" \
    --wait
else
  echo "k3d cluster ${CLUSTER_NAME} already exists."
fi

# Use k3d context
kubectl config use-context "k3d-${CLUSTER_NAME}"

# Create namespaces
kubectl get ns "${ARGO_NS}" >/dev/null 2>&1 || kubectl create namespace "${ARGO_NS}"
kubectl get ns "${DEV_NS}"  >/dev/null 2>&1 || kubectl create namespace "${DEV_NS}"

# Install Argo CD via official manifests
echo "Installing Argo CD in namespace ${ARGO_NS}..."
kubectl apply -n "${ARGO_NS}" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "${ARGO_NS}" --timeout=300s || true

# Apply Argo CD Application that points to your Git repo
kubectl apply -f "${REPO_ROOT}/p3/confs/argocd-app.yaml"

echo "k3d, namespaces, Argo CD, and Application configured."
