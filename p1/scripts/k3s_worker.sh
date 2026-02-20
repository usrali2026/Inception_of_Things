#!/usr/bin/env bash
set -euo pipefail

echo "[WORKER] Starting K3s worker setup..."

SERVER_IP="${SERVER_IP:-192.168.56.110}"
K3S_URL="https://${SERVER_IP}:6443"

# Choose the interface used to reach the server (eth1 in your setup).
IFACE="${IFACE:-}"
if [ -z "$IFACE" ]; then
  IFACE="$(ip -o -4 route get "$SERVER_IP" \
    | awk '{for(i=1;i<=NF;i++) if ($i=="dev"){print $(i+1); exit}}')"
fi

if [ -z "$IFACE" ] || [ "$IFACE" = "lo" ]; then
  echo "[WORKER][ERROR] Could not detect network interface."
  exit 1
fi

IP="${WORKER_IP:-}"
if [ -z "$IP" ]; then
  IP="$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)"
fi
: "${IP:=192.168.56.111}"

TOKEN="${CLUSTER_TOKEN:-IOT42ClusterToken}"

echo "[WORKER] Using iface=${IFACE}, IP=${IP}, server=${K3S_URL}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# Enforce config via config.yaml (loaded regardless of install method).
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF
server: "${K3S_URL}"
token: "${TOKEN}"
node-ip: "${IP}"
flannel-iface: "${IFACE}"
EOF

if systemctl list-unit-files | grep -q '^k3s-agent.service'; then
  echo "[WORKER] k3s-agent already installed, restarting to apply config.yaml"
  sudo systemctl daemon-reload
  sudo systemctl restart k3s-agent
else
  echo "[WORKER] Installing k3s agent and joining cluster..."
  curl -sfL https://get.k3s.io | sudo sh -s - agent
fi

# Optional kubectl convenience (not required on worker, but harmless)
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl 2>/dev/null || true

echo "[WORKER] Setup complete."

