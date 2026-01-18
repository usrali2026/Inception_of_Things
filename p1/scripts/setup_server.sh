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
: "${IP:=192.168.56.110}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# If k3s already installed, skip reinstall
if systemctl list-unit-files | grep -q '^k3s.service'; then
  echo "[INFO] k3s already installed, skipping install"
else
  echo "[INFO] Installing k3s server on ${IP} (${IFACE})"
  curl -sfL https://get.k3s.io \
    | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip ${IP} --advertise-address ${IP} --tls-san ${IP}" \
      sh -
fi

# Ensure confs directory exists and share the join token to the synced folder
sudo mkdir -p /vagrant/confs
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/node-token
sudo chmod 644 /vagrant/confs/node-token

# kubectl convenience
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
