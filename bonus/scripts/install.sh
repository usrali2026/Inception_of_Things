#!/bin/bash
set -e

echo "=============================="
echo " [1/5] Creating K3d cluster"
echo "=============================="
k3d cluster create iot-bonus \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --port "8888:30888@loadbalancer" \
  --port "8929:30929@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" \
  --agents 0

sleep 15
kubectl get nodes

echo "=============================="
echo " [2/5] Install Helm"
echo "=============================="
if ! command -v helm &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm version

echo "=============================="
echo " [3/5] Install ArgoCD"
echo "=============================="
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl create namespace dev
kubectl create namespace gitlab

echo "Waiting for ArgoCD..."
kubectl wait --for=condition=available \
  --timeout=300s deployment/argocd-server -n argocd

echo "=============================="
echo " [4/5] Install GitLab via Helm"
echo "=============================="
helm repo add gitlab https://charts.gitlab.io/
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 600s \
  --set global.hosts.domain=gitlab.local \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.hosts.https=false \
  --set certmanager.install=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.enabled=false \
  --set global.ingress.class=nginx \
  --set nginx-ingress.enabled=true \
  --set gitlab.webservice.minReplicas=1 \
  --set gitlab.webservice.maxReplicas=1 \
  --set gitlab.sidekiq.minReplicas=1 \
  --set gitlab.sidekiq.maxReplicas=1 \
  --set gitlab.gitlab-shell.minReplicas=1 \
  --set gitlab.gitlab-shell.maxReplicas=1 \
  --set registry.hpa.minReplicas=1 \
  --set registry.hpa.maxReplicas=1 \
  --set minio.persistence.size=2Gi \
  --set postgresql.primary.persistence.size=2Gi \
  --set redis.master.persistence.size=1Gi \
  --set gitlab.gitaly.persistence.size=2Gi \
  --set prometheus.install=false \
  --set grafana.enabled=false \
  --set gitlab.kas.enabled=false

echo "=============================="
echo " [5/5] Waiting for GitLab"
echo "=============================="
echo "GitLab takes 5-10 minutes to start..."
kubectl wait --for=condition=available \
  --timeout=600s deployment/gitlab-webservice-default -n gitlab || \
  kubectl get pods -n gitlab

echo ""
echo "GitLab root password:"
kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab -o jsonpath='{.data.password}' | base64 -d
echo ""
echo ""
echo "Add to /etc/hosts:"
echo "  127.0.0.1  gitlab.local"
echo "  sudo bash -c \"echo '127.0.0.1 gitlab.local' >> /etc/hosts\""
