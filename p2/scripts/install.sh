#!/bin/bash
set -e
export INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --node-ip 10.0.56.110 --bind-address 10.0.56.110 --advertise-address 10.0.56.110 --flannel-iface eth1"
curl -sfL https://get.k3s.io | sh -
echo "Waiting for K3s..."
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do sleep 3; done
kubectl get nodes -o wide
