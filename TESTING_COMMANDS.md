# Testing p1: K3s and Vagrant

---

## p1 - Configuration Check

### 1. Vagrantfile presence and content
- Ensure Vagrantfile exists in p1.
- Check it defines two VMs: alrahmouS and alrahmouSW.
- Verify VM resources: 1 CPU, 1024MB RAM.
- Check network interface (enp0s8) IPs: 192.168.56.110 and 192.168.56.111.
- Hostnames: alrahmouS and alrahmouSW.
- SSH is passwordless.
- K3s install scripts present.

---

## p1 - Usage

### 1. Start the VMs
```sh
cd p1
vagrant up
```
### 2. Check VM Status
```sh
vagrant status
```
### 3. SSH into VMs
```sh
vagrant ssh alrahmouS -c "echo 'Connected to alrahmouS'"
vagrant ssh alrahmouSW -c "echo 'Connected to alrahmouSW'"
```
### 4. Check network interface IP addresses
```sh
vagrant ssh alrahmouS -c "ip addr show eth1 | grep 'inet '"
vagrant ssh alrahmouSW -c "ip addr show eth1 | grep 'inet '"
```
### 5. Check hostnames
```sh
vagrant ssh alrahmouS -c "hostname"
vagrant ssh alrahmouSW -c "hostname"
```
### 6. Check K3s installation
```sh
vagrant ssh alrahmouS -c "k3s --version || k3s -v"
vagrant ssh alrahmouSW -c "k3s --version || k3s -v"
```
### 7. Check cluster membership
```sh
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
```

---

## p2 - Configuration Check

### 1. Application manifests presence and content
- Ensure p2 contains app1-deployment.yaml, app2-deployment.yaml, app3-deployment.yaml, ingress.yaml.
- Check each manifest for correct app name, image, and replica count (app2: 3 replicas).
- Verify ingress rules for app1.com, app2.com, and default to app3.

---

## p2 - Usage

### 1. Check K3s cluster status and nodes
```sh
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
```
### 2. Check all resources in kube-system namespace
```sh
vagrant ssh alrahmouS -c "kubectl get all -n kube-system"
```
### 3. Check deployed applications and replicas
```sh
vagrant ssh alrahmouS -c "kubectl get deployments -n default"
vagrant ssh alrahmouS -c "kubectl get pods -n default"
```
### 4. Check Ingress configuration
```sh
vagrant ssh alrahmouS -c "kubectl get ingress -n default"
```
### 5. Test application routing using curl
```sh
vagrant ssh alrahmouS -c "curl -H 'Host: app1.com' http://192.168.56.110"
vagrant ssh alrahmouS -c "curl -H 'Host: app2.com' http://192.168.56.110"
vagrant ssh alrahmouS -c "curl -H 'Host: app3.com' http://192.168.56.110"
```

---

## p3 - Configuration Check

### 1. K3d/Argo CD manifests presence and content
- Ensure p3 contains argocd-app.yaml, argocd-namespace.yaml, dev-namespace.yaml, manifests/, k3d-setup.sh.
- Check argocd-app.yaml for correct repoURL, path, and syncPolicy.
- Verify Docker image names and tags (v1, v2) in manifests.

---

## p3 - Usage

### 1. Start K3d infrastructure
```sh
cd p3
./k3d-setup.sh
```
### 2. Check namespaces
```sh
kubectl get ns
# Should list 'argocd' and 'dev'
```
### 3. Check pods in dev namespace
```sh
kubectl get pods -n dev
```
### 4. Check required services
```sh
kubectl get svc --all-namespaces
```
### 5. Check Argo CD installation
```sh
kubectl get pods -n argocd
# Access Argo CD UI in browser (URL and credentials provided by group)
```
### 6. Check GitHub repository naming
# Confirm your repo name includes your login (e.g., usrali2026/Inception_of_Things)
### 7. Check Docker image and tags
# Confirm your Docker image is named with your login and has v1 and v2 tags on Docker Hub
### 8. Application update workflow
# Edit manifest to v2, commit/push, sync in Argo CD, verify update

---

## Bonus - Configuration Check
- Ensure bonus folder contains Gitlab deployment/configuration files.
- Check gitlab-namespace.yaml, gitlab-deployment.yaml, and integration steps.

---

## Bonus - Usage
### 1. Test Gitlab functionality
# Create a new repository, add code, verify in Gitlab UI.
### 2. Validate Argo CD with local Gitlab repository
# Use Gitlab repo in Argo CD, repeat application update workflow.
### 3. Final validation
# If sync and version change work, bonus is validated.

---

**Note:**
- All commands are to be run from the root of the repository unless otherwise specified.
- Ensure you have Vagrant and required providers (libvirt/VirtualBox) installed
