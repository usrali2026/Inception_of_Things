#!/bin/bash
set -e
echo "Deploying apps..."
kubectl apply -f /vagrant/confs/deployments.yaml
echo "Waiting for deployments..."
kubectl wait --for=condition=available --timeout=120s deployment/app-one
kubectl wait --for=condition=available --timeout=120s deployment/app-two
kubectl wait --for=condition=available --timeout=120s deployment/app-three
echo "Deploying Ingress..."
kubectl apply -f /vagrant/confs/ingress.yaml
echo ""
kubectl get all
kubectl get ingress
