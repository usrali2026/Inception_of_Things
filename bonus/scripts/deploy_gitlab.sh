#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Deploying GitLab via Helm...${NC}"

# Add GitLab Helm repo
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update

# Install or upgrade
if helm list -n gitlab | grep -q "^gitlab"; then
    echo -e "${YELLOW}GitLab already installed — upgrading...${NC}"
    helm upgrade gitlab gitlab/gitlab \
        -n gitlab \
        -f bonus/confs/gitlab-values.yaml \
        --timeout 600s
else
    echo "Installing GitLab (this takes 5–10 minutes)..."
    helm install gitlab gitlab/gitlab \
        -n gitlab \
        -f bonus/confs/gitlab-values.yaml \
        --timeout 600s
fi

# Wait for webservice pod
echo "Waiting for GitLab webservice to be ready (up to 15 min)..."
kubectl wait --for=condition=ready pod \
    -l app=webservice \
    -n gitlab \
    --timeout=900s 2>/dev/null || echo "Timeout passed — checking status..."

# Extra settle time
echo "Allowing GitLab to finish initializing..."
sleep 30

# Pod status report
echo ""
echo -e "${YELLOW}GitLab pod status:${NC}"
kubectl get pods -n gitlab

# Get root password
echo ""
echo -e "${GREEN}========================================"
echo -e "  GitLab Deployed!"
echo -e "========================================${NC}"
echo -n "  Root password: "
kubectl get secret gitlab-gitlab-initial-root-password \
    -n gitlab \
    -o jsonpath='{.data.password}' | base64 --decode
echo ""
echo ""

# Start port-forward for browser access
# Note: port 8080 is safe — K3d loadbalancer uses 9080 (fixed in setup.sh)
pkill -f "port-forward.*gitlab-webservice" 2>/dev/null || true
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8080:8181 >/dev/null 2>&1 &

echo -e "${GREEN}GitLab accessible at: http://localhost:8080${NC}"
echo -e "${YELLOW}Note: If the page doesn't load yet, wait 1–2 more minutes.${NC}"
