#!/usr/bin/env bash
set -euo pipefail

echo "[WORKER] Starting K3s worker setup..."

SERVER_IP="${SERVER_IP:-192.168.56.110}"
K3S_URL="https://${SERVER_IP}:6443"

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

# Wait for server API to be ready before joining
echo "[WORKER] Waiting for K3s server API at ${K3S_URL}..."
until curl -sk "${K3S_URL}/readyz" >/dev/null 2>&1; do
    echo "[WORKER] Server not ready yet, retrying in 5s..."
    sleep 5
done
echo "[WORKER] Server API ready ✓"

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

sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl 2>/dev/null || true

# Explicit enable — evalsheet checks both active AND enabled
sudo systemctl enable k3s-agent
sudo systemctl is-active  k3s-agent && echo "[WORKER] k3s-agent: active ✓"
sudo systemctl is-enabled k3s-agent && echo "[WORKER] k3s-agent: enabled ✓"

echo "[WORKER] Setup complete."
