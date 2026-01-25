#!/usr/bin/env bash
set -euo pipefail

echo "[SERVER] Starting K3s server setup..."

IFACE="${IFACE:-}"
if [ -z "$IFACE" ]; then
  IFACE=$(ip -o -4 route show to default | awk '{print $5}' | grep -v '^lo$' | head -n1)
fi

if [ -z "$IFACE" ]; then
  echo "[SERVER][ERROR] Could not detect network interface."
  exit 1
fi

IP="${SERVER_IP:-$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)}"
: "${IP:=192.168.56.110}"

TOKEN="${CLUSTER_TOKEN:-IOT42ClusterToken}"

echo "[SERVER] Using iface=${IFACE}, IP=${IP}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

if systemctl list-unit-files | grep -q '^k3s.service'; then
  echo "[SERVER] k3s already installed, skipping"
else
  echo "[SERVER] Installing k3s server..."
  curl -sfL https://get.k3s.io \
    | sudo K3S_TOKEN="${TOKEN}" \
           INSTALL_K3S_EXEC="server \
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

echo "[SERVER] Setup complete."

