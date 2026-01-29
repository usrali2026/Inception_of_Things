#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[02_deploy_argocd] $*"
}

log "Ensuring argocd namespace exists"
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd

# You can replace this with a local manifest in confs/argocd/install.yaml if you prefer.
log "Installing Argo CD into argocd namespace"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log "Waiting for Argo CD deployments to become ready"
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-application-controller -n argocd --timeout=300s

# Expose argocd-server as NodePort so you can reach it from inside the VM.
log "Patching argocd-server Service to NodePort on 30080"
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort","ports":[{"name":"https","port":443,"targetPort":8080,"nodePort":30080}]}}'

log "Argo CD installed. Access via: https://<VM-IP>:30080 (self-signed cert)"
