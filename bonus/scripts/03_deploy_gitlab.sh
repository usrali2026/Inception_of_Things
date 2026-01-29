#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[03_deploy_gitlab] $*"
}

NAMESPACE="gitlab"

log "Ensuring namespace '${NAMESPACE}' exists"
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

log "Adding/updating GitLab Helm repo"
helm repo add gitlab https://charts.gitlab.io >/dev/null 2>&1 || true
helm repo update

VALUES_FILE="/vagrant/bonus/confs/gitlab/values.yaml"
if [ ! -f "${VALUES_FILE}" ]; then
  log "ERROR: ${VALUES_FILE} not found. Create it before running this script."
  exit 1
fi

log "Installing/upgrading GitLab using values file ${VALUES_FILE}"
helm upgrade --install gitlab gitlab/gitlab \
  --namespace "${NAMESPACE}" \
  -f "${VALUES_FILE}" \
  --timeout 30m \
  --wait

log "GitLab pods status:"
kubectl get pods -n "${NAMESPACE}"
