# manifests directory for Argo CD

This directory contains the Kubernetes manifests for your application, to be deployed in the `dev` namespace by Argo CD.

## Files
- `deployment.yaml`: Deploys the sample app using the Docker image `wil42/playground` (change tag to `v1` or `v2` as needed).
- `service.yaml`: Exposes the app on port 8888 within the cluster.

## How to update the app version
1. Edit `deployment.yaml` and change the image tag (e.g., from `v1` to `v2`).
2. Commit and push the change to your GitHub repository.
3. Argo CD will automatically sync and update the deployment in your cluster.

## Example
```
# Change this line in deployment.yaml:
image: wil42/playground:v1
# to
image: wil42/playground:v2
```

## Accessing Argo CD
1. Port forward:
   ```
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
2. Get admin password:
   ```
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```
3. Login to Argo CD web UI at https://localhost:8080
