#!/bin/bash
# Script to install K3d, Docker, Argo CD, and required tools
set -e

echo "=== K3d and Argo CD Setup ==="

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "Please do not run as root"
   exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker if not present
if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
    echo "Or run: newgrp docker"
else
    echo "Docker is already installed: $(docker --version)"
fi

# Start Docker service
if ! docker info >/dev/null 2>&1; then
    echo "Starting Docker service..."
    sudo systemctl start docker || sudo service docker start
    sleep 2
fi

# Install K3d if not present
if ! command_exists k3d; then
    echo "Installing K3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "K3d installed: $(k3d version)"
else
    echo "K3d is already installed: $(k3d version)"
fi

# Check if cluster already exists
if k3d cluster list | grep -q "inception"; then
    echo "K3d cluster 'inception' already exists. Deleting it..."
    k3d cluster delete inception
fi

# Create K3d cluster
echo "Creating K3d cluster 'inception'..."
k3d cluster create inception \
    --port "8888:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --api-port 6443 \
    --wait

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=120s || true

# Install kubectl if not present
if ! command_exists kubectl; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed: $(kubectl version --client --short)"
else
    echo "kubectl is already installed: $(kubectl version --client --short)"
fi

# Set kubeconfig context
export KUBECONFIG=$(k3d kubeconfig write inception)
echo "Kubeconfig set to: $KUBECONFIG"

# Install Argo CD
echo "Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready (this may take a few minutes)..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s || true

# Get Argo CD admin password
echo ""
echo "=== Argo CD Setup Complete ==="
echo "To access Argo CD:"
echo "1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
echo "3. Login: argocd login localhost:8080"
echo ""
echo "Or install Argo CD CLI:"
echo "  Linux: curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "  chmod +x /usr/local/bin/argocd"
echo ""
