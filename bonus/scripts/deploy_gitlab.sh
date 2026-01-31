#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Deploying GitLab...${NC}"

# Add GitLab Helm repository
echo "Adding GitLab Helm repository..."
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Check if GitLab is already installed
if helm list -n gitlab | grep -q gitlab; then
    echo -e "${YELLOW}GitLab already installed. Upgrading...${NC}"
    helm upgrade gitlab gitlab/gitlab \
        -n gitlab \
        -f bonus/confs/gitlab-values.yaml \
        --timeout 600s
else
    echo "Installing GitLab..."
    helm install gitlab gitlab/gitlab \
        -n gitlab \
        -f bonus/confs/gitlab-values.yaml \
        --timeout 600s
fi

echo "Waiting for GitLab pods to be ready (this may take 5-10 minutes)..."
kubectl wait --for=condition=ready pod \
    -l app=webservice \
    -n gitlab \
    --timeout=900s 2>/dev/null || echo "Continuing..."

# Check pod status
echo ""
echo -e "${YELLOW}GitLab pod status:${NC}"
kubectl get pods -n gitlab

# Wait a bit more for all services
sleep 30

# Get root password
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitLab Deployed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "GitLab root password:"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode
echo ""
echo ""

# Start port-forward in background
echo -e "${YELLOW}Starting port-forward to GitLab...${NC}"
pkill -f "port-forward.*gitlab-webservice" 2>/dev/null || true
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8080:8181 > /dev/null 2>&1 &

echo -e "${GREEN}GitLab is accessible at: http://localhost:8080${NC}"
echo -e "Username: ${YELLOW}root${NC}"
echo ""
echo -e "${YELLOW}Note: GitLab may take a few more minutes to be fully ready.${NC}"
echo -e "${YELLOW}If the page doesn't load immediately, wait a bit and try again.${NC}"
