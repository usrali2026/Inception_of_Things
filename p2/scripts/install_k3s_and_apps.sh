# p2/scripts/install_k3s_and_apps.sh
#!/usr/bin/env bash
set -e

# Install K3s server (Traefik ingress enabled by default)
curl -sfL https://get.k3s.io | sh -s - server --node-name alrahmouS

# Make kubectl available easily
sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl || true

echo "Waiting for K3s system pods to come up..."
sleep 40

# Optional: wait until kube-system pods are ready
sudo kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=180s || true

# Apply applications (Deployments + Services)
sudo kubectl apply -f /vagrant/confs/apps.yaml

# Wait a bit to ensure Services exist before Ingress
sleep 10

# Apply Ingress
sudo kubectl apply -f /vagrant/confs/ingress.yaml

echo "K3s + 3 apps + Ingress deployed on alrahmouS"
