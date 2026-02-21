#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Must be run from repo root
if [ ! -f "bonus/scripts/setup.sh" ]; then
    echo -e "${RED}Run this script from the repo root: bash bonus/scripts/setup.sh${NC}"
    exit 1
fi

echo -e "${GREEN}========================================"
echo -e "  Inception-of-Things — Bonus Setup"
echo -e "========================================${NC}"
echo ""

# ── Prerequisites ────────────────────────────────────────────────────
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

if ! command -v docker &>/dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh && rm get-docker.sh
    sudo usermod -aG docker "$USER"
    echo -e "${RED}Docker installed. Re-login required. Run this script again.${NC}"
    exit 0
fi

if ! command -v kubectl &>/dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
fi

if ! command -v k3d &>/dev/null; then
    echo "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

if ! command -v helm &>/dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Added: ArgoCD CLI required for repo registration
if ! command -v argocd &>/dev/null; then
    echo "Installing ArgoCD CLI..."
    curl -sSL -o argocd-linux-amd64 \
        https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
fi

echo -e "${GREEN}✓ All prerequisites ready${NC}"
echo ""

# ── K3d Cluster ──────────────────────────────────────────────────────
echo -e "${YELLOW}[2/6] Setting up K3d cluster...${NC}"

CLUSTER_NAME="iot-bonus"
CONTEXT_NAME="k3d-iot-bonus"

if ! k3d cluster list | grep -q "${CLUSTER_NAME}"; then
    # fixed: port 9080 (not 8080) to avoid conflict with GitLab port-forward on 8080
    k3d cluster create "${CLUSTER_NAME}" \
        --api-port 6550 \
        -p "9080:80@loadbalancer" \
        --agents 2
    kubectl cluster-info
else
    echo -e "${GREEN}✓ Cluster already exists${NC}"
    kubectl config use-context "${CONTEXT_NAME}"
fi

# ── Namespaces ───────────────────────────────────────────────────────
echo -e "${YELLOW}Creating namespaces...${NC}"
for ns in argocd dev gitlab; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
echo -e "${GREEN}✓ Namespaces: argocd, dev, gitlab${NC}"
echo ""

# ── Argo CD ──────────────────────────────────────────────────────────
echo -e "${YELLOW}[3/6] Installing Argo CD...${NC}"

if ! kubectl get deployment argocd-server -n argocd &>/dev/null; then
    kubectl apply -n argocd \
        -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    echo "Waiting for all Argo CD pods to be ready..."
    # fixed: wait for all key deployments, not just argocd-server
    kubectl wait --for=condition=available --timeout=300s \
        deployment/argocd-server \
        deployment/argocd-repo-server \
        deployment/argocd-applicationset-controller \
        deployment/argocd-notifications-controller \
        -n argocd
else
    echo -e "${GREEN}✓ Argo CD already installed${NC}"
fi

echo -e "${GREEN}✓ Argo CD ready${NC}"
echo ""

# ── GitLab ───────────────────────────────────────────────────────────
echo -e "${YELLOW}[4/6] Deploying GitLab (5–10 min)...${NC}"
bash bonus/scripts/deploy_gitlab.sh
echo ""

# ── Argo CD Repo Registration ────────────────────────────────────────
echo -e "${YELLOW}[5/6] Registering GitLab repo in Argo CD...${NC}"

# Port-forward Argo CD UI
echo "Starting Argo CD port-forward on :8081..."
pkill -f "port-forward.*argocd-server" 2>/dev/null || true
kubectl port-forward svc/argocd-server -n argocd 8081:443 >/dev/null 2>&1 &
sleep 6

# Get Argo CD password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)

# Wait for GitLab initial root password secret to exist
echo "Waiting for GitLab root password secret..."
until kubectl get secret gitlab-gitlab-initial-root-password -n gitlab &>/dev/null; do
    echo "  still waiting..."
    sleep 10
done
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password \
    -n gitlab -o jsonpath='{.data.password}' | base64 --decode)

# Login to Argo CD CLI
argocd login localhost:8081 \
    --username admin \
    --password "$ARGOCD_PASSWORD" \
    --insecure

# Register local GitLab repo (uses internal cluster DNS — no port-forward needed)
argocd repo add \
    http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git \
    --username root \
    --password "$GITLAB_PASSWORD" \
    --insecure-skip-server-verification

echo -e "${GREEN}✓ GitLab repo registered in Argo CD${NC}"
echo ""

# ── Summary ──────────────────────────────────────────────────────────
echo -e "${YELLOW}[6/6] Verifying cluster state...${NC}"
kubectl get pods -n argocd
kubectl get pods -n gitlab
echo ""

echo -e "${GREEN}========================================"
echo -e "  Setup Complete!"
echo -e "========================================${NC}"
echo ""
echo -e "  GitLab UI  → ${CYAN}http://localhost:8080${NC}"
echo -e "              user: ${YELLOW}root${NC} / pass: ${YELLOW}${GITLAB_PASSWORD}${NC}"
echo ""
echo -e "  Argo CD UI → ${CYAN}https://localhost:8081${NC}"
echo -e "              user: ${YELLOW}admin${NC} / pass: ${YELLOW}${ARGOCD_PASSWORD}${NC}"
echo ""
echo -e "${YELLOW}Manual steps remaining:${NC}"
echo "  1. Open GitLab → create project named 'iot-app'"
echo "  2. Clone and push the app manifests:"
echo "       git clone http://localhost:8080/root/iot-app.git"
echo "       cd iot-app"
echo "       cp ../bonus/confs/deployment.yaml ."
echo "       cp ../bonus/confs/service.yaml ."
echo "       git add . && git commit -m 'v1' && git push"
echo "  3. Apply Argo CD Application:"
echo "       kubectl apply -f bonus/confs/argocd-app-gitlab.yaml"
echo "  4. Verify sync:"
echo "       kubectl get application -n argocd"
echo "       kubectl get pods -n dev"
