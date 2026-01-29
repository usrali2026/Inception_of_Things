#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[06_deploy_app_with_argocd] $*"
}

APP_NS="dev"
ARGO_APP_MANIFEST="/vagrant/bonus/confs/argocd/app.yaml"

if [ ! -f "${ARGO_APP_MANIFEST}" ]; then
  log "ERROR: ${ARGO_APP_MANIFEST} not found. Create it with your Argo CD Application definition."
  exit 1
fi

log "Ensuring namespace '${APP_NS}' exists"
kubectl get ns "${APP_NS}" >/dev/null 2>&1 || kubectl create namespace "${APP_NS}"

log "Applying Argo CD Application manifest"
kubectl apply -f "${ARGO_APP_MANIFEST}"

log "Current Argo CD Applications:"
kubectl get applications.argoproj.io -n argocd || true

log "Waiting for app pods in namespace '${APP_NS}' (if any) to show up"
sleep 10
kubectl get pods -n "${APP_NS}"
