#!/usr/bin/env bash

set -euo pipefail

# Detect network interface automatically if not set
if [ -z "${IFACE:-}" ]; then
  IFACE=$(ip -o -4 route show to default | awk '{print $5}' | grep -v '^lo$' | head -n1)
  if [ -z "$IFACE" ]; then
    echo "[ERROR] Could not detect network interface. Please set IFACE manually."
    exit 1
  fi
fi
IP=${IP:-$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)}
SERVER_IP=${SERVER_IP:-192.168.56.110}
K3S_URL="https://${SERVER_IP}:6443"

# wait for token from server (wait up to 10 minutes)
echo "Waiting for K3s server token..."
for i in {1..300}; do
  if [ -f /vagrant/confs/node-token ]; then
    echo "Token found!"
    break
  fi
  echo "Waiting for /vagrant/confs/node-token... ($i/300)"
  sleep 2
done

if [ ! -f /vagrant/confs/node-token ]; then
  echo "[ERROR] K3s server token not found after 10 minutes."
  echo "Please ensure the server VM (wilS) has completed setup and the token file exists in /vagrant/confs."
  exit 1
fi

TOKEN=$(cat /vagrant/confs/node-token)
if [ -z "$TOKEN" ]; then
  echo "[ERROR] Token file is empty."
  exit 1
fi

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# K3s agent; pin node IP to host-only NIC
curl -sfL https://get.k3s.io | K3S_URL="${K3S_URL}" K3S_TOKEN="${TOKEN}" INSTALL_K3S_EXEC="agent --node-ip ${IP} --flannel-iface ${IFACE}" sh -

sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl || true
