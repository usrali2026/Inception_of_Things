#!/bin/bash
set -e

# Step 1: Provision VMs and install K3s
cd p1
vagrant up
vagrant ssh server -c "bash /vagrant/setup_server.sh"
vagrant ssh worker -c "bash /vagrant/setup_worker.sh"
cd ..

# Step 2: Deploy applications and ingress
kubectl apply -f p2/app1-deployment.yaml
kubectl apply -f p2/app2-deployment.yaml
kubectl apply -f p2/app3-deployment.yaml
kubectl apply -f p2/ingress.yaml

# Step 3: Set up K3d and Argo CD
bash p3/k3d-setup.sh
kubectl apply -f p3/argocd-namespace.yaml
kubectl apply -f p3/dev-namespace.yaml
kubectl apply -f p3/argocd-app.yaml

# Step 4: Integrate Gitlab
kubectl apply -f bonus/gitlab-namespace.yaml
kubectl apply -f bonus/gitlab-deployment.yaml

# Validation commands
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
kubectl get ingress --all-namespaces
kubectl get applications -n argocd || echo "Argo CD CLI not installed"
