# Inception-of-Things (IoT) – Modern README

> Hands-on Kubernetes project for 42, using **K3s**, **K3d**, **Vagrant**, **Argo CD**, and optionally **GitLab**. Implements the official subject v4.0. All code and configs are organized for fast setup and validation.

---

## 🚀 Project Structure

| Folder | Technology         | Purpose                                              |
|--------|--------------------|-----------------------------------------------------|
| p1     | Vagrant + K3s      | 2-node K3s cluster (Server + ServerWorker VMs)      |
| p2     | Vagrant + K3s      | 1 K3s VM, 3 web apps, Ingress (host-based routing)  |
| p3     | K3d + Argo CD      | GitOps: app in `dev` namespace, auto-updated via Git |
| bonus  | GitLab + Helm      | Local GitLab, Argo CD pulling from GitLab repo      |

All config is under `p1/`, `p2/`, `p3/`, and optional `bonus/` at repo root.

---

## 🛠️ Prerequisites

- Ubuntu 22.04+ host VM (recommended) or Ubuntu 24.04
- Vagrant (VirtualBox or libvirt) - **libvirt recommended**
- Docker
- kubectl
- Git
- libvirt and libvirt-dev (for vagrant-libvirt plugin)

**Host resources:** ≥8 GB RAM, 4 vCPUs, 50 GB disk

**Installation:**

1. **Install Vagrant:**
   ```bash
   # Add HashiCorp repository
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install vagrant -y
   ```

2. **Install vagrant-libvirt plugin:**
   ```bash
   sudo apt install libvirt-dev -y
   vagrant plugin install vagrant-libvirt
   ```

3. **Install Docker, kubectl, k3d (for Part 3):**
   ```bash
   sudo apt install docker.io -y
   sudo systemctl enable --now docker
   # kubectl and k3d will be installed by p3/scripts/install_k3d_argocd.sh
   ```

Quick check:
```bash
vagrant --version
docker --version
kubectl version --client
git --version
virsh --version  # For libvirt
```

**Note:** If you see `[fog][WARNING] Unrecognized arguments: libvirt_ip_command` warnings, these are harmless and can be ignored. Alternatively, you can suppress them using the wrapper script in `p1/vagrant-wrapper.sh` or by adding a function to your `~/.zshrc` (see troubleshooting section).

---

## 1️⃣ Part 1 – K3s & Vagrant (`p1`)

Spin up two VMs (Server, ServerWorker) with K3s using Vagrant.

**Folder:**
```
p1/
  Vagrantfile              # Defines 2 VMs: alrahmouS (server) and alrahmouSW (worker)
  scripts/
    k3s_server.sh          # Installs and configures K3s server
    k3s_worker.sh          # Joins worker node to K3s cluster
  confs/                   # Configuration files
  vagrant-wrapper.sh       # Optional wrapper to suppress fog warnings
```

**Setup:**
```bash
cd p1
vagrant up
```

This will:
- Create 2 VMs: `alrahmouS` (192.168.56.110) and `alrahmouSW` (192.168.56.111)
- Install K3s server on `alrahmouS`
- Join `alrahmouSW` as a worker node
- Configure networking on the `iot56` libvirt network

**Validation:**
```bash
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
```

Expected output:
- 2 nodes: `alrahmous` (control-plane) and `alrahmousw` (worker)
- Both with STATUS: Ready
- Correct IPs: 192.168.56.110 and 192.168.56.111

**Useful commands:**
```bash
vagrant status              # Check VM status
vagrant ssh alrahmouS       # SSH into server VM
vagrant ssh alrahmouSW      # SSH into worker VM
vagrant halt                # Stop all VMs
vagrant destroy             # Delete all VMs
```

---

## 2️⃣ Part 2 – K3s + 3 Apps + Ingress (`p2`)

Single VM with K3s, three web apps, and Ingress routing by Host header.

**Folder:**
```
p2/
  Vagrantfile
  scripts/
    install_k3s.sh          # Installs K3s and deploys apps
  confs/
    apps-ingress.yaml       # Combined: Deployments + Services + Ingress
                            # - app1: 1 replica
                            # - app2: 3 replicas  
                            # - app3: 1 replica (default backend)
```

**Setup:**
```bash
cd p2
vagrant up
```

This will:
- Create 1 VM: `alrahmouS` (192.168.56.110)
- Install K3s server
- Create `webapps` namespace
- Deploy 3 applications (app1, app2, app3)
- Configure Ingress with host-based routing

**Validation:**
```bash
# Check all resources
vagrant ssh alrahmouS -c "kubectl get all -n webapps"

# Check ingress
vagrant ssh alrahmouS -c "kubectl get ingress -n webapps"
```

Expected output:
- 3 deployments: app1-deployment (1/1), app2-deployment (3/3), app3-deployment (1/1)
- 3 services: app1-service, app2-service, app3-service
- 5 pods total (1 app1 + 3 app2 + 1 app3)
- 1 ingress: webapps-ingress with hosts app1.com, app2.com

**Ingress Testing:**
From your host machine (not inside the VM):
```bash
curl -H "Host: app1.com" 192.168.56.110      # Returns: app1
curl -H "Host: app2.com" 192.168.56.110      # Returns: app2
curl -H "Host: whatever.com" 192.168.56.110  # Returns: app3 (default backend)
```

**Architecture:**
- Traefik (K3s default ingress controller) handles routing
- Host-based routing: different Host headers route to different services
- app3 serves as the default backend for unmatched hosts

---

## 3️⃣ Part 3 – K3d + Argo CD (`p3`)

K3d cluster with Argo CD, deploying an app to the `dev` namespace from this GitHub repo. Demonstrates GitOps workflow with automatic synchronization.

**Folder:**
```
p3/
  scripts/
    install_k3d_argocd.sh  # Single script: installs tools, creates cluster, deploys Argo CD
  confs/
    argocd-app.yaml        # Argo CD Application manifest
                          # - Points to GitHub repo: https://github.com/usrali2026/Inception_of_Things.git
                          # - Path: p3/dev-app
                          # - Auto-sync enabled with prune and selfHeal
  dev-app/
    deployment.yaml        # App deployment (wil-playground image: v1/v2)
    service.yaml          # Service exposing app on port 8888
```

**Setup:**
```bash
cd p3
bash scripts/install_k3d_argocd.sh
```

This script will:
1. Install Docker, kubectl, and k3d (if not already installed)
2. Create k3d cluster named `iot-p3` (1 server + 1 agent)
3. Create namespaces: `argocd` and `dev`
4. Install Argo CD in the `argocd` namespace
5. Apply Argo CD Application manifest pointing to this GitHub repo
6. Argo CD automatically syncs and deploys the app from `p3/dev-app/`

**Validation:**
```bash
# Check namespaces
kubectl get ns
# Should show: argocd, dev

# Check Argo CD pods (all should be Running)
kubectl get pods -n argocd
# Expected: 7 pods (application-controller, repo-server, server, redis, dex-server, etc.)

# Check Argo CD Application status
kubectl get application -n argocd
# Should show: dev-app, Synced, Healthy

# Check deployed app
kubectl get pods -n dev
# Should show: wil-playground pod Running

# Check all resources in dev namespace
kubectl get all -n dev
# Should show: deployment, service, pod
```

**GitOps Workflow - Version Switch Demo:**

1. **Update the image version:**
   ```bash
   # Edit p3/dev-app/deployment.yaml
   # Change: image: wil42/playground:v1 → image: wil42/playground:v2
   ```

2. **Commit and push:**
   ```bash
   git add p3/dev-app/deployment.yaml
   git commit -m "Update image to v2"
   git push origin main
   ```

3. **Argo CD automatically syncs:**
   - Argo CD detects the change in GitHub (auto-sync enabled)
   - Updates the deployment
   - Kubernetes performs a rolling update
   - New pod with v2 image is created
   - Old pod with v1 image is terminated

4. **Verify the update:**
   ```bash
   # Check deployment image
   kubectl get deployment wil-playground -n dev -o jsonpath='{.spec.template.spec.containers[0].image}'
   # Should show: wil42/playground:v2
   
   # Check pod image
   kubectl get pod -n dev -l app=wil-playground -o jsonpath='{.items[0].spec.containers[0].image}'
   # Should show: wil42/playground:v2
   
   # Check Argo CD sync status
   kubectl get application dev-app -n argocd
   # Should show: Synced, Healthy
   ```

**Manual Sync (if needed):**
```bash
# Trigger manual refresh
kubectl annotate application dev-app -n argocd argocd.argoproj.io/refresh=hard --overwrite

# Or sync manually via Argo CD CLI (if installed)
argocd app sync dev-app
```

**Access Argo CD UI:**
```bash
# Port-forward Argo CD server
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Access UI at: https://localhost:8080
# Username: admin
# Password: (from command above)
```

**Cleanup:**
```bash
# Delete k3d cluster
k3d cluster delete iot-p3

# Or delete everything
kubectl delete application dev-app -n argocd
k3d cluster delete iot-p3
```

---

## ⭐ Bonus – GitLab Integration (`bonus`)

Local GitLab deployed in `gitlab` namespace via Helm, used as a Git source for Argo CD instead of GitHub.

**Folder:**
```
bonus/
  confs/
    gitlab-namespace.yaml
  scripts/
    deploy_gitlab.sh
```
**Usage:**
```bash
bonus/scripts/deploy_gitlab.sh
kubectl get ns
kubectl get pods -n gitlab
```
GitLab UI: http://localhost:8080
Create a project with manifests (like `p3/k8s/dev`) and configure Argo CD to pull from GitLab. Demo v1→v2 image tag change and Argo CD sync.

---

## 🧪 Validation Cheat Sheet

**Part 1:**
```bash
cd p1
vagrant up
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
# Expected: 2 nodes (alrahmous, alrahmousw) with IPs 192.168.56.110/111
```

**Part 2:**
```bash
cd p2
vagrant up
vagrant ssh alrahmouS -c "kubectl get all -n webapps"
# Expected: 3 deployments, 3 services, 5 pods

# Test ingress (from host)
curl -H "Host: app1.com" 192.168.56.110      # app1
curl -H "Host: app2.com" 192.168.56.110      # app2
curl -H "Host: whatever.com" 192.168.56.110  # app3
```

**Part 3:**
```bash
cd p3
bash scripts/install_k3d_argocd.sh
kubectl get ns                                    # Should show argocd, dev
kubectl get pods -n argocd                        # 7 pods Running
kubectl get application -n argocd                 # dev-app Synced Healthy
kubectl get pods -n dev                           # wil-playground Running
```

**Bonus:**
```bash
bonus/scripts/deploy_gitlab.sh
kubectl get pods -n gitlab
# Access GitLab at http://localhost:8080
```

---

## 🔧 Troubleshooting

### Vagrant libvirt Warnings

If you see `[fog][WARNING] Unrecognized arguments: libvirt_ip_command` warnings:

**Option 1:** Use the wrapper script:
```bash
cd p1
./vagrant-wrapper.sh status
./vagrant-wrapper.sh up
```

**Option 2:** Add to `~/.zshrc` or `~/.bashrc`:
```bash
unalias vagrant 2>/dev/null
vagrant() {
  local tmpfile
  tmpfile=$(mktemp)
  command vagrant "$@" > "$tmpfile" 2>&1
  local exit_code=$?
  grep -v "\[fog\]\[WARNING\] Unrecognized arguments: libvirt_ip_command" "$tmpfile"
  rm -f "$tmpfile"
  return $exit_code
}
```

### Argo CD Not Syncing

If Argo CD doesn't automatically sync after a Git push:

```bash
# Trigger manual refresh
kubectl annotate application dev-app -n argocd argocd.argoproj.io/refresh=hard --overwrite

# Check application status
kubectl get application dev-app -n argocd -o yaml

# Check repo server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --tail=50
```

### K3d Cluster Issues

```bash
# List clusters
k3d cluster list

# Delete and recreate
k3d cluster delete iot-p3
k3d cluster create iot-p3 --servers 1 --agents 1

# Check cluster status
kubectl cluster-info
```

### Network Issues (Part 1 & 2)

If VMs can't reach each other:

```bash
# Check libvirt network
virsh net-list
virsh net-info iot56

# Restart network
virsh net-destroy iot56
virsh net-start iot56
```

---

## 📚 Additional Resources

- **K3s Documentation:** https://k3s.io/
- **K3d Documentation:** https://k3d.io/
- **Argo CD Documentation:** https://argo-cd.readthedocs.io/
- **Vagrant libvirt:** https://github.com/vagrant-libvirt/vagrant-libvirt

---

> This README is for quick setup and validation. For full requirements, see `en.subject_v4.0.pdf`.

<div align="center">⁂</div>
