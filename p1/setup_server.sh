#!/usr/bin/env bash
set -euo pipefail

IFACE=${IFACE:-eth1}
IP=${IP:-$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)}
: "${IP:=192.168.56.110}"

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# K3s server; advertise on host-only NIC
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip ${IP} --advertise-address ${IP} --flannel-iface ${IFACE}" sh -

# share the join token to the synced folder
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/node-token
sudo chmod 644 /vagrant/confs/node-token

# kubectl convenience
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
