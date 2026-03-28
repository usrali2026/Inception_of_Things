#!/bin/bash
set -e
echo "Waiting for token..."
until [ -f /vagrant/node-token ]; do sleep 2; done
TOKEN=$(cat /vagrant/node-token)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://10.0.56.110:6443 \
  K3S_TOKEN=$TOKEN \
  INSTALL_K3S_EXEC="agent --node-ip 10.0.56.111 --flannel-iface eth1" \
  sh -
echo "Worker joined."
