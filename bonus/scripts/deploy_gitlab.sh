#!/usr/bin/env bash
# Automated GitLab deployment script for K3d/ArgoCD lab
# Requirements: helm, kubectl, k3d cluster running (from p3)

set -e

NAMESPACE=gitlab
RELEASE=gitlab
DOMAIN=localhost
EMAIL="your-email@example.com"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../.."

# Use k3d cluster context created in p3 (adjust name if needed)
kubectl config use-context "k3d-k3d-iot" || true

# Create gitlab namespace if it doesn't exist
kubectl apply -f "${SCRIPT_DIR}/../confs/gitlab-namespace.yaml"

# Ensure Helm is installed
if ! command -v helm >/dev/null 2>&1; then
  echo "Helm not found, installing..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add GitLab Helm repo
helm repo add gitlab https://charts.gitlab.io/ || true
helm repo update

# Install GitLab with minimal config for local use
helm upgrade --install "$RELEASE" gitlab/gitlab \
  --namespace "$NAMESPACE" \
  --set global.hosts.domain="$DOMAIN" \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email="$EMAIL" \
  --set gitlab-runner.install=false \
  --timeout 600s

# Wait for GitLab webservice to be available
kubectl wait --for=condition=available deployment/gitlab-webservice-default -n "$NAMESPACE" --timeout=600s || true

# Get GitLab root password
echo "GitLab root password:"
kubectl get secret gitlab-gitlab-initial-root-password -n "$NAMESPACE" -o jsonpath='{.data.password}' | base64 -d; echo

# Port-forward for local browser access
kubectl port-forward svc/gitlab-webservice-default -n "$NAMESPACE" 8080:80 &
echo "GitLab is accessible at http://localhost:8080"
echo "Create a project there and point an Argo CD Application to its Git repo URL."
