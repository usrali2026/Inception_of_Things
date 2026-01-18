#!/usr/bin/env bash
set -euo pipefail

# Install K3s server (Traefik ingress enabled by default)
curl -sfL https://get.k3s.io | sh -s - server --node-name alrahmouS

# Make kubectl available easily
sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl || true

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Waiting for K3s system pods to come up..."
sleep 30

# Wait until kube-system pods are ready (best-effort)
sudo kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=180s || true

# Apply applications (Deployments + Services)
sudo kubectl apply -f /vagrant/confs/apps.yaml

# Wait a bit to ensure Services exist before Ingress
sleep 10

# Apply Ingress
sudo kubectl apply -f /vagrant/confs/ingress.yaml

echo "K3s + 3 apps + Ingress deployed on alrahmouS"
