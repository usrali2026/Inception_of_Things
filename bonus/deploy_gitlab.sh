#!/bin/bash
# Automated Gitlab deployment script for K3d/ArgoCD lab
# Requirements: helm, kubectl, k3d cluster running

set -e

NAMESPACE=gitlab
RELEASE=gitlab
DOMAIN=localhost
EMAIL=your-email@example.com

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE

# Add Gitlab Helm repo
helm repo add gitlab https://charts.gitlab.io/ || true
helm repo update

# Install Gitlab with minimal config
helm upgrade --install $RELEASE gitlab/gitlab \
  --namespace $NAMESPACE \
  --set global.hosts.domain=$DOMAIN \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email=$EMAIL \
  --set redis.image.tag=6.2.7 \
  --set gitlab-runner.install=false \
  --timeout 600s

# Wait for Gitlab webservice to be available
kubectl wait --for=condition=available deployment/gitlab-webservice-default -n $NAMESPACE --timeout=600s

# Get Gitlab root password
kubectl get secret gitlab-gitlab-initial-root-password -n $NAMESPACE -o jsonpath='{.data.password}' | base64 -d; echo

# Port-forward for local access
kubectl port-forward svc/gitlab-webservice-default -n $NAMESPACE 8080:80 &
echo "Gitlab is accessible at http://localhost:8080"
