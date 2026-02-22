#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Deploying GitLab via Helm...${NC}"

# Ensure namespace exists
kubectl get ns gitlab >/dev/null 2>&1 || kubectl create namespace gitlab

# Add GitLab Helm repo
helm repo add gitlab https://charts.gitlab.io/ >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

VALUES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/confs/gitlab-values.yaml"

if [[ ! -f "$VALUES_PATH" ]]; then
  echo "ERROR: gitlab-values.yaml not found at: $VALUES_PATH"
  exit 1
fi

# Install or upgrade
if helm list -n gitlab | grep -q "^gitlab"; then
    echo -e "${YELLOW}GitLab already installed — upgrading...${NC}"
    helm upgrade gitlab gitlab/gitlab \
        -n gitlab \
        -f "$VALUES_PATH" \
        --timeout 600s
else
    echo "Installing GitLab (this may take several minutes)..."
    helm install gitlab gitlab/gitlab \
        -n gitlab \
        -f "$VALUES_PATH" \
        --timeout 600s
fi

# Wait for webservice pod
echo "Waiting for GitLab webservice to be ready (up to 15 min)..."
if ! kubectl wait --for=condition=ready pod \
        -l app=webservice \
        -n gitlab \
        --timeout=900s; then
    echo "WARNING: Timeout while waiting for GitLab webservice pod."
fi

echo "Allowing GitLab to finish initializing..."
sleep 30

echo ""
echo -e "${YELLOW}GitLab pod status:${NC}"
kubectl get pods -n gitlab

echo ""
echo -e "${GREEN}========================================"
echo -e "  GitLab Deployed!"
echo -e "========================================${NC}"

echo -n "  Root password: "
kubectl get secret gitlab-gitlab-initial-root-password \
    -n gitlab \
    -o jsonpath='{.data.password}' | base64 --decode || echo -n "N/A"
echo ""
echo ""

# Port-forward for browser access
#  - GitLab chart exposes webservice on service gitlab-webservice-default:8181 by default.
#  - We forward it to localhost:8080.
pkill -f "port-forward.*gitlab-webservice-default" >/dev/null 2>&1 || true
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8080:8181 >/dev/null 2>&1 &

echo -e "${GREEN}GitLab accessible at: http://localhost:8080${NC}"
echo -e "${YELLOW}If the page doesn't load yet, wait 1–2 more minutes.${NC}"
