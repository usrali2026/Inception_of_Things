#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  GitLab Cleanup${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}This will remove GitLab and all associated resources.${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo -e "${RED}Cleanup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup...${NC}"

# Kill port-forward processes
echo "Stopping port-forward processes..."
pkill -f "port-forward.*gitlab" 2>/dev/null || echo "No port-forward processes found"

# Remove ArgoCD applications
echo "Removing ArgoCD applications..."
kubectl delete application -n argocd wil-playground-gitlab --ignore-not-found=true

# Uninstall GitLab
if helm list -n gitlab | grep -q gitlab; then
    echo "Uninstalling GitLab Helm release..."
    helm uninstall gitlab -n gitlab --wait --timeout=300s
else
    echo "GitLab Helm release not found"
fi

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
kubectl wait --for=delete pod --all -n gitlab --timeout=120s 2>/dev/null || true

# Delete PVCs
echo "Deleting persistent volume claims..."
kubectl delete pvc -n gitlab --all --timeout=60s 2>/dev/null || true

# Delete namespace
echo "Deleting gitlab namespace..."
kubectl delete namespace gitlab --wait=true --timeout=120s 2>/dev/null || true

# Force remove if stuck
if kubectl get namespace gitlab &>/dev/null; then
    echo "Forcing namespace removal..."
    kubectl patch namespace gitlab -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
    kubectl delete namespace gitlab --force --grace-period=0 2>/dev/null || true
fi

# Clean up Helm repo
echo "Removing GitLab Helm repository..."
helm repo remove gitlab 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Verify
echo ""
if kubectl get namespace gitlab &>/dev/null; then
    echo -e "${RED}⚠ gitlab namespace still exists${NC}"
else
    echo -e "${GREEN}✓ gitlab namespace removed${NC}"
fi

if helm list -n gitlab 2>/dev/null | grep -q gitlab; then
    echo -e "${RED}⚠ GitLab Helm release still exists${NC}"
else
    echo -e "${GREEN}✓ GitLab Helm release removed${NC}"
fi
