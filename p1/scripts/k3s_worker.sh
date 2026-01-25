#!/usr/bin/env bash
set -euo pipefail

echo "[WORKER] Starting K3s worker setup..."

IFACE="${IFACE:-}"
if [ -z "$IFACE" ]; then
  IFACE=$(ip -o -4 route show to default | awk '{print $5}' | grep -v '^lo$' | head -n1)
fi

if [ -z "$IFACE" ]; then
  echo "[WORKER][ERROR] Could not detect network interface."
  exit 1
fi

SERVER_IP="${SERVER_IP:-192.168.56.110}"
IP="${WORKER_IP:-$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)}"
TOKEN="${CLUSTER_TOKEN:-IOT42ClusterToken}"
K3S_URL="https://${SERVER_IP}:6443"

echo "[WORKER] Using iface=${IFACE}, IP=${IP}, server=${K3S_URL}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

if systemctl list-unit-files | grep -q '^k3s-agent.service'; then
  echo "[WORKER] k3s-agent already installed, restarting"
  sudo systemctl restart k3s-agent
else
  echo "[WORKER] Installing k3s agent and joining cluster..."
  curl -sfL https://get.k3s.io \
    | sudo K3S_URL="${K3S_URL}" \
           K3S_TOKEN="${TOKEN}" \
           INSTALL_K3S_EXEC="agent \
             --node-ip ${IP} \
             --flannel-iface ${IFACE}" \
           sh -
fi

sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl || true

echo "[WORKER] Setup complete."

