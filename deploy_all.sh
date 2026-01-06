#!/bin/bash
# Deployment script for Inception-of-Things project
# This script deploys all parts of the project: K3s VMs, applications, K3d, Argo CD, and optionally Gitlab
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
info "Checking prerequisites..."
MISSING_DEPS=()

if ! command_exists vagrant; then
    MISSING_DEPS+=("vagrant")
fi

if ! command_exists kubectl; then
    MISSING_DEPS+=("kubectl")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    error "Missing required dependencies: ${MISSING_DEPS[*]}"
    error "Please install the missing dependencies before running this script."
    exit 1
fi

info "All prerequisites met."

# Ask if user wants to deploy bonus (Gitlab)
DEPLOY_BONUS=false
if [ "${1:-}" = "--with-bonus" ] || [ "${1:-}" = "-b" ]; then
    DEPLOY_BONUS=true
    info "Bonus section (Gitlab) will be deployed."
else
    read -p "Deploy bonus section (Gitlab)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DEPLOY_BONUS=true
    fi
fi

# Step 1: Provision VMs and install K3s
info "Step 1: Provisioning VMs and installing K3s..."
if [ -d "p1" ]; then
    cd p1
    if [ -f "Vagrantfile" ]; then
        info "Starting Vagrant VMs..."
        vagrant up
        
        info "Installing K3s on server (wilS)..."
        vagrant ssh wilS -c "bash /vagrant/scripts/setup_server.sh" || {
            error "Failed to setup K3s server"
            exit 1
        }
        
        info "Installing K3s on worker (wilSW)..."
        vagrant ssh wilSW -c "bash /vagrant/scripts/setup_worker.sh" || {
            error "Failed to setup K3s worker"
            exit 1
        }
        
        info "Step 1 completed successfully."
    else
        warn "Vagrantfile not found in p1/, skipping Part 1."
    fi
    cd ..
else
    warn "p1/ directory not found, skipping Part 1."
fi

# Step 2: Deploy applications and ingress
info "Step 2: Deploying applications and ingress..."
if [ -d "p2" ]; then
    # Check if kubectl can connect to cluster
    if kubectl cluster-info &>/dev/null; then
        info "Applying application deployments..."
        kubectl apply -f p2/app1-deployment.yaml
        kubectl apply -f p2/app2-deployment.yaml
        kubectl apply -f p2/app3-deployment.yaml
        kubectl apply -f p2/ingress.yaml
        
        info "Waiting for deployments to be ready..."
        kubectl wait --for=condition=available deployment/app1 --timeout=120s || warn "app1 deployment not ready"
        kubectl wait --for=condition=available deployment/app2 --timeout=120s || warn "app2 deployment not ready"
        kubectl wait --for=condition=available deployment/app3 --timeout=120s || warn "app3 deployment not ready"
        
        info "Step 2 completed successfully."
    else
        warn "kubectl cannot connect to cluster. Make sure K3s is running and kubeconfig is set."
        warn "Skipping Part 2."
    fi
else
    warn "p2/ directory not found, skipping Part 2."
fi

# Step 3: Set up K3d and Argo CD
info "Step 3: Setting up K3d and Argo CD..."
if [ -d "p3" ]; then
    if [ -f "p3/k3d-setup.sh" ]; then
        info "Running K3d setup script..."
        bash p3/k3d-setup.sh || {
            error "K3d setup failed"
            exit 1
        }
        
        # Wait a bit for cluster to be ready
        sleep 5
        
        info "Creating namespaces..."
        kubectl apply -f p3/argocd-namespace.yaml
        kubectl apply -f p3/dev-namespace.yaml
        
        info "Applying Argo CD application..."
        if [ -f "p3/argocd-app.yaml" ]; then
            # Check if argocd-app.yaml has placeholder values
            if grep -q "<your-org>" p3/argocd-app.yaml; then
                warn "Argo CD app manifest contains placeholder values."
                warn "Please update p3/argocd-app.yaml with your repository URL before applying."
                read -p "Continue anyway? [y/N]: " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    warn "Skipping Argo CD application deployment."
                else
                    kubectl apply -f p3/argocd-app.yaml
                fi
            else
                kubectl apply -f p3/argocd-app.yaml
            fi
        else
            warn "argocd-app.yaml not found, skipping Argo CD application deployment."
        fi
        
        info "Step 3 completed successfully."
    else
        warn "k3d-setup.sh not found in p3/, skipping Part 3."
    fi
else
    warn "p3/ directory not found, skipping Part 3."
fi

# Step 4: Integrate Gitlab (bonus)
if [ "$DEPLOY_BONUS" = true ]; then
    info "Step 4: Integrating Gitlab (bonus)..."
    if [ -d "bonus" ]; then
        if kubectl cluster-info &>/dev/null; then
            info "Creating Gitlab namespace..."
            kubectl apply -f bonus/gitlab-namespace.yaml
            
            if [ -f "bonus/gitlab-deployment.yaml" ]; then
                warn "Gitlab deployment requires Helm. See bonus/gitlab-deployment.yaml for instructions."
                warn "Manual deployment required:"
                warn "  helm repo add gitlab https://charts.gitlab.io/"
                warn "  helm install gitlab gitlab/gitlab --namespace gitlab --set global.hosts.domain=localhost"
            else
                warn "gitlab-deployment.yaml not found."
            fi
        else
            warn "kubectl cannot connect to cluster. Skipping Gitlab deployment."
        fi
    else
        warn "bonus/ directory not found, skipping bonus section."
    fi
else
    info "Skipping bonus section (Gitlab)."
fi

# Validation commands
info "Running validation checks..."
echo ""
info "=== Cluster Nodes ==="
kubectl get nodes 2>/dev/null || warn "Cannot get nodes (cluster may not be accessible)"

echo ""
info "=== Pods (all namespaces) ==="
kubectl get pods --all-namespaces 2>/dev/null || warn "Cannot get pods"

echo ""
info "=== Services (all namespaces) ==="
kubectl get services --all-namespaces 2>/dev/null || warn "Cannot get services"

echo ""
info "=== Ingress (all namespaces) ==="
kubectl get ingress --all-namespaces 2>/dev/null || warn "Cannot get ingress"

echo ""
info "=== Argo CD Applications ==="
if kubectl get applications -n argocd &>/dev/null; then
    kubectl get applications -n argocd
else
    warn "Argo CD applications not found (Argo CD may not be installed or CLI not configured)"
fi

echo ""
info "=== Deployment Summary ==="
info "Part 1 (K3s VMs): Check with 'vagrant status' in p1/ directory"
info "Part 2 (Applications): Check with 'kubectl get pods -n default'"
info "Part 3 (K3d/Argo CD): Check with 'kubectl get pods -n argocd'"
if [ "$DEPLOY_BONUS" = true ]; then
    info "Bonus (Gitlab): Check with 'kubectl get pods -n gitlab'"
fi

info "Deployment script completed!"
