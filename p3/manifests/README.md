# manifests directory for Argo CD

This directory contains the Kubernetes manifests for your application, to be deployed in the `dev` namespace by Argo CD.

## Files
- `deployment.yaml`: Deploys the sample app using the Docker image `wil42/playground` (change tag to `v1` or `v2` as needed).
- `service.yaml`: Exposes the app on port 8888 within the cluster.

## How to update the app version
1. Edit `deployment.yaml` and change the image tag (e.g., from `v1` to `v2`).
2. Commit and push the change to your GitHub repository.
3. Argo CD will automatically sync and update the deployment in your cluster.

## How to test the running version
1. Port-forward the service:
    ```
    kubectl port-forward -n dev svc/sample-app 8890:8888
    ```
2. In another terminal, run:
    ```
    curl http://localhost:8890/
    ```
    You should see a response like `{ "status": "ok", "message": "v1" }` or `"v2"` depending on the deployed version.

## Demonstration checklist for evaluation
- Show Argo CD application status is **Synced** and **Healthy**:
   ```
   kubectl get applications -n argocd
   ```
- Show pod status in the dev namespace:
   ```
   kubectl get pods -n dev
   ```
- Show version update by changing the image tag, committing, pushing, and verifying with curl as above.

## Notes
- Make your repository public before evaluation so Argo CD can access it.
- You can roll back to v1 by repeating the update process with the v1 tag.

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
