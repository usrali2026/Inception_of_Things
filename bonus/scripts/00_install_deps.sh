#!/usr/bin/env bash
set -euo pipefail

# Simple colored log helper
log() {
  echo "[00_install_deps] $*"
}

log "Updating apt index"
sudo apt-get update -y

log "Installing base packages (curl, ca-certificates, gnupg, lsb-release, git)"
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git

# -----------------------------
# Docker
# -----------------------------
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker (CE)"
  # Official Docker convenience script (fine for a lab VM)
  curl -fsSL https://get.docker.com | sh

  log "Adding vagrant user to docker group (if exists)"
  if id "vagrant" >/dev/null 2>&1; then
    sudo usermod -aG docker vagrant
  fi

  log "Enabling and starting Docker service"
  sudo systemctl enable docker
  sudo systemctl start docker
else
  log "Docker already installed, skipping"
fi

# -----------------------------
# k3d
# -----------------------------
if ! command -v k3d >/dev/null 2>&1; then
  log "Installing k3d"
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
  log "k3d already installed, skipping"
fi

# -----------------------------
# kubectl
# -----------------------------
if ! command -v kubectl >/dev/null 2>&1; then
  log "Installing kubectl"
  KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
  curl -L "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /tmp/kubectl
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
else
  log "kubectl already installed, skipping"
fi

# -----------------------------
# Helm
# -----------------------------
if ! command -v helm >/dev/null 2>&1; then
  log "Installing Helm"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  log "Helm already installed, skipping"
fi

# -----------------------------
# Argo CD CLI
# -----------------------------
if ! command -v argocd >/dev/null 2>&1; then
  log "Installing Argo CD CLI"
  ARGOCD_VERSION="v2.12.0"  # pin a known version if you like
  curl -L "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64" -o /tmp/argocd
  sudo install -m 0755 /tmp/argocd /usr/local/bin/argocd
  rm -f /tmp/argocd
else
  log "Argo CD CLI already installed, skipping"
fi

log "Installation of dependencies completed"
