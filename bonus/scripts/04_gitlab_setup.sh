#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[04_gitlab_setup] $*"
}

NAMESPACE="gitlab"

log "Trying to retrieve initial root password secret name"
SECRET_NAME="$(kubectl get secret -n "${NAMESPACE}" | awk '/root-password/ {print $1; exit}')"

if [ -z "${SECRET_NAME:-}" ]; then
  log "Could not automatically find root-password secret. Check secrets in namespace '${NAMESPACE}'."
  kubectl get secret -n "${NAMESPACE}"
  exit 1
fi

ROOT_PASSWORD="$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o jsonpath='{.data.password}' | base64 -d)"

log "GitLab likely available at: http://gitlab.local (or via the Service/Ingress you configured)"
log "Login with username: root"
log "Initial root password: ${ROOT_PASSWORD}"

cat <<EOF

Next manual steps (for simplicity, do via UI):
1. Open GitLab in a browser from the VM (or host, depending on your networking).
2. Login as root using the password above.
3. Create a new project (e.g. group 'lab' / project 'app-config').
4. Make the project public OR create a personal access token with 'read_repository' scope.
5. Note the HTTPS URL of the repo (e.g. http://gitlab.local/lab/app-config.git).

You will use this URL in Argo CD's Application manifest (repoURL).
EOF
