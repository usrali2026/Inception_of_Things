#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}========================================"
echo -e "  Bonus Cleanup"
echo -e "========================================${NC}"

# Kill all port-forwards
echo -e "${YELLOW}Stopping port-forwards...${NC}"
pkill -f "port-forward" 2>/dev/null && echo -e "${GREEN}✓ Port-forwards stopped${NC}" || true

# Uninstall GitLab Helm release
if helm list -n gitlab 2>/dev/null | grep -q "^gitlab"; then
    echo -e "${YELLOW}Uninstalling GitLab...${NC}"
    helm uninstall gitlab -n gitlab --timeout 120s
    echo -e "${GREEN}✓ GitLab uninstalled${NC}"
fi

# Delete K3d cluster (removes everything: argocd, dev, gitlab namespaces)
if k3d cluster list 2>/dev/null | grep -q "iot-bonus"; then
    echo -e "${YELLOW}Deleting K3d cluster iot-bonus...${NC}"
    k3d cluster delete iot-bonus
    echo -e "${GREEN}✓ Cluster deleted${NC}"
fi

# Remove leftover PVCs if any
kubectl delete pvc --all -n gitlab 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Cleanup complete. Run setup.sh to start fresh.${NC}"
