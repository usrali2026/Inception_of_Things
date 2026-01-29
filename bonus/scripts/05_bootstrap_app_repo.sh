#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[05_bootstrap_app_repo] $*"
}

# Usage:
#   GITLAB_APP_REPO_URL=http://gitlab.local/lab/app-config.git ./scripts/05_bootstrap_app_repo.sh
# If repo is private, you can embed credentials in the URL:
#   http://token-name:token-value@gitlab.local/lab/app-config.git

REPO_URL="${GITLAB_APP_REPO_URL:-}"

if [ -z "${REPO_URL}" ]; then
  log "ERROR: GITLAB_APP_REPO_URL env var not set."
  log "Example: export GITLAB_APP_REPO_URL=http://gitlab.local/lab/app-config.git"
  exit 1
fi

WORKDIR="/tmp/app-config-repo"
rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"

log "Initializing local repo at ${WORKDIR}"
cd "${WORKDIR}"
git init

log "Copying manifests from /vagrant/bonus/confs/app"
cp -r /vagrant/bonus/confs/app/* .

git add .
git commit -m "Initial commit of Kubernetes app manifests"

log "Pushing to ${REPO_URL}"
git branch -M main
git remote add origin "${REPO_URL}"
git push -u origin main

log "Repository bootstrapped with manifests on branch 'main'"
