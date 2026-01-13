#!/usr/bin/env bash
set -e

# Install Docker (simple version; you can switch to official Docker repo if you prefer)
sudo apt-get update -y
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Docker CE from official repo
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  # Add Docker’s official GPG key
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  sudo usermod -aG docker "$USER" || true
fi

# Install kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
fi

# Install k3d
if ! command -v k3d >/dev/null 2>&1; then
  echo "Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Optional: install argocd CLI (nice for debugging)
if ! command -v argocd >/dev/null 2>&1; then
  echo "Installing Argo CD CLI..."
  ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '\"' -f4)
  curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
  chmod +x argocd
  sudo mv argocd /usr/local/bin/argocd
fi

echo "Tools installed: Docker, kubectl, k3d, (argocd CLI)."
echo "You may need to log out and log back in for docker group changes to take effect."
