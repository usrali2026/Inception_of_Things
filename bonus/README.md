# Bonus: Gitlab Integration and Automation

## Overview
This folder contains everything needed to deploy Gitlab locally in your K3d/ArgoCD lab and integrate it with a CI/CD pipeline.

## Files
- `gitlab-deployment.yaml`: Instructions for deploying Gitlab using Helm.
- `gitlab-namespace.yaml`: Namespace manifest for Gitlab.
- `deploy_gitlab.sh`: Automation script to deploy Gitlab (run with `./deploy_gitlab.sh`).
- `.gitlab-ci.yml`: Sample Gitlab CI/CD pipeline for building and deploying an application to your cluster.

## How `.gitlab-ci.yml` Integrates with Your Cluster
- The pipeline builds a Docker image and pushes it to the Gitlab registry.
- It then clones your GitOps repository (used by ArgoCD) and updates the image tag in the Kubernetes deployment manifest.
- When the manifest is updated and pushed, ArgoCD automatically deploys the new version to your K3d cluster.
- This enables full GitOps-style continuous deployment from Gitlab to your local Kubernetes cluster.

## How to Use the Automation Script
1. Ensure you have a running K3d cluster and Helm installed.
2. Run `./deploy_gitlab.sh` to deploy Gitlab locally in the `gitlab` namespace.
3. The script will port-forward Gitlab to `http://localhost:8080` and print the root password.

## Example: Gitlab Pipeline Deploying to K3d/ArgoCD
1. Push code changes to your Gitlab repository.
2. The pipeline builds and pushes a new Docker image.
3. The pipeline updates the deployment manifest in your GitOps repo.
4. ArgoCD detects the change and deploys the new version to your cluster.

**Note:**
- For the pipeline to update manifests, set the `GITOPS_REPO_URL` variable in your Gitlab CI/CD settings.
- Make sure ArgoCD is configured to watch your GitOps repository.
- If you want to run `kubectl` commands from Gitlab CI, you must provide the cluster's kubeconfig and necessary permissions.

---
For more details, see the comments in each file or ask for a specific example.
