#!/usr/bin/env bash
set -euo pipefail

echo "[P2] Starting K3s server setup..."

IFACE="${IFACE:-}"
if [ -z "$IFACE" ]; then
  IFACE=$(ip -o -4 route show to default | awk '{print $5}' | grep -v '^lo$' | head -n1)
fi

if [ -z "$IFACE" ]; then
  echo "[P2][ERROR] Could not detect network interface."
  exit 1
fi

IP="${SERVER_IP:-$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)}"
: "${IP:=192.168.56.110}"

echo "[P2] Using iface=${IFACE}, IP=${IP}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# Install K3s server if not already installed
if systemctl list-unit-files | grep -q '^k3s.service'; then
  echo "[P2] k3s already installed, skipping install"
else
  echo "[P2] Installing k3s server..."
  curl -sfL https://get.k3s.io \
    | sudo INSTALL_K3S_EXEC="server \
        --write-kubeconfig-mode=644 \
        --node-ip=${IP} \
        --advertise-address=${IP} \
        --tls-san=${IP}" \
      sh -
fi

# kubectl convenience
if [ ! -x /usr/local/bin/kubectl ]; then
  sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
fi

# Wait for node Ready
echo "[P2] Waiting for node to be Ready..."
for i in {1..60}; do
  if sudo k3s kubectl get nodes 2>/dev/null | grep -q " Ready "; then
    echo "[P2] Node is Ready."
    break
  fi
  sleep 2
done

# Apply app + ingress manifests
echo "[P2] Applying app and ingress manifests..."
sudo k3s kubectl apply -f /vagrant/confs/apps-ingress.yaml

echo "[P2] Setup complete."
