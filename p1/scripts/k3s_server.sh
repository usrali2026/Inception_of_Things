#!/usr/bin/env bash
set -euo pipefail

echo "[SERVER] Starting K3s server setup..."

# Choose the interface used to reach the project subnet (eth1 in your setup).
# You can override with IFACE=eth1 if you want.
CLUSTER_TEST_IP="${CLUSTER_TEST_IP:-192.168.56.1}"

IFACE="${IFACE:-}"
if [ -z "$IFACE" ]; then
  IFACE="$(ip -o -4 route get "$CLUSTER_TEST_IP" \
    | awk '{for(i=1;i<=NF;i++) if ($i=="dev"){print $(i+1); exit}}')"
fi

if [ -z "$IFACE" ] || [ "$IFACE" = "lo" ]; then
  echo "[SERVER][ERROR] Could not detect network interface."
  exit 1
fi

IP="${SERVER_IP:-}"
if [ -z "$IP" ]; then
  IP="$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)"
fi
: "${IP:=192.168.56.110}"

TOKEN="${CLUSTER_TOKEN:-IOT42ClusterToken}"

echo "[SERVER] Using iface=${IFACE}, IP=${IP}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# Enforce config via config.yaml (independent from how the install script was invoked).
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF
write-kubeconfig-mode: "0644"
token: "${TOKEN}"
node-ip: "${IP}"
advertise-address: "${IP}"
tls-san:
  - "${IP}"
flannel-iface: "${IFACE}"
EOF

if systemctl list-unit-files | grep -q '^k3s.service'; then
  echo "[SERVER] k3s already installed, restarting to apply config.yaml"
  sudo systemctl daemon-reload
  sudo systemctl restart k3s
else
  echo "[SERVER] Installing k3s server..."
  curl -sfL https://get.k3s.io | sudo sh -s - server
fi

# kubectl convenience
if [ ! -x /usr/local/bin/kubectl ]; then
  sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
fi

echo "[SERVER] Setup complete."

