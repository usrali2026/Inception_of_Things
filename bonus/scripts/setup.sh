#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Inception-of-Things - Bonus Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running in VM
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found. Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}Docker installed. Please log out and back in, then run this script again.${NC}"
    exit 0
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Installing...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Check k3d
if ! command -v k3d &> /dev/null; then
    echo -e "${RED}k3d not found. Installing...${NC}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Check helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Helm not found. Installing...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo -e "${GREEN}✓ All prerequisites installed${NC}"
echo ""

# Check if k3d cluster exists
if ! k3d cluster list | grep -q "k3d-iot"; then
    echo -e "${YELLOW}Creating k3d cluster...${NC}"
    k3d cluster create k3d-iot --api-port 6550 -p "8080:80@loadbalancer" --agents 2
    kubectl cluster-info
else
    echo -e "${GREEN}✓ k3d cluster already exists${NC}"
    kubectl config use-context k3d-k3d-iot
fi

# Create namespaces
echo -e "${YELLOW}Creating namespaces...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespaces created${NC}"

# Install ArgoCD if not already installed
if ! kubectl get deployment argocd-server -n argocd &> /dev/null; then
    echo -e "${YELLOW}Installing ArgoCD...${NC}"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Get ArgoCD password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo -e "${GREEN}ArgoCD installed!${NC}"
    echo -e "ArgoCD Admin Password: ${YELLOW}${ARGOCD_PASSWORD}${NC}"
else
    echo -e "${GREEN}✓ ArgoCD already installed${NC}"
fi

# Deploy GitLab
echo ""
echo -e "${YELLOW}Deploying GitLab (this will take 5-10 minutes)...${NC}"
./bonus/scripts/deploy_gitlab.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "GitLab UI: ${YELLOW}http://localhost:8080${NC}"
echo -e "ArgoCD UI: ${YELLOW}http://localhost:8081${NC} (run: kubectl port-forward svc/argocd-server -n argocd 8081:443)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Log into GitLab at http://localhost:8080 with root and the password shown above"
echo "2. Create a new project called 'iot-app'"
echo "3. Push deployment.yaml and service.yaml from bonus/confs/"
echo "4. Apply the ArgoCD application: kubectl apply -f bonus/confs/argocd-app-gitlab.yaml"
echo "5. Verify the app is synced in ArgoCD"
