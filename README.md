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

- Ubuntu 22.04 host VM (recommended)
- Vagrant (VirtualBox or libvirt)
- Docker
- kubectl
- Git

**Host resources:** ≥8 GB RAM, 4 vCPUs, 50 GB disk

Quick check:
```bash
vagrant --version
docker --version
kubectl version --client
git --version
```

---

## 1️⃣ Part 1 – K3s & Vagrant (`p1`)

Spin up two VMs (Server, ServerWorker) with K3s using Vagrant.

**Folder:**
```
p1/
  Vagrantfile
  scripts/
    setup_server.sh
    setup_worker.sh
  confs/
    node-token
```
**Usage:**
```bash
cd p1
vagrant up
```
**Validation:**
```bash
vagrant ssh <login>S -c "kubectl get nodes -o wide"
```
Should show 2 nodes with correct hostnames and IPs (192.168.56.110/111).

---

## 2️⃣ Part 2 – K3s + 3 Apps + Ingress (`p2`)

Single VM with K3s, three web apps, and Ingress routing by Host header.

**Folder:**
```
p2/
  Vagrantfile
  scripts/
    install_k3s_and_apps.sh
  confs/
    apps.yaml        # Deployments + Services for app1, app2 (3 replicas), app3
    ingress.yaml     # Ingress rules for app1.com, app2.com, default → app3
```
**Usage:**
```bash
cd p2
vagrant up
```
**Validation:**
```bash
vagrant ssh <login>S -c "kubectl get all"
```
Should show 3 deployments, 3 services, 5 pods (3 for app2).

**Ingress test:**
```bash
curl -H "Host:app1.com" 192.168.56.110      # app1
curl -H "Host:app2.com" 192.168.56.110      # app2
curl -H "Host:whatever.com" 192.168.56.110  # app3 (default)
```

---

## 3️⃣ Part 3 – K3d + Argo CD (`p3`)

K3d cluster with Argo CD, deploying an app to the `dev` namespace from this GitHub repo. Supports auto-updating via Git push.

**Folder:**
```
p3/
  scripts/
    install_tools.sh      # Installs Docker, kubectl, k3d, argocd CLI
    setup_k3d_argocd.sh   # Creates k3d cluster, namespaces, Argo CD, app
  confs/
    argocd-app.yaml       # Argo CD Application (repoURL + path)
  k8s/
    dev/
      deployment.yaml     # App (image v1/v2)
      service.yaml        # Service for app on port 8888
```
**Usage:**
```bash
p3/scripts/install_tools.sh
p3/scripts/setup_k3d_argocd.sh
```
**Validation:**
```bash
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
```
Should show `argocd` and `dev` namespaces, app running in `dev`.

**Version switch demo:**
1. Edit `p3/k8s/dev/deployment.yaml` and change image tag from `v1` to `v2`, commit & push.
2. Wait for Argo CD to sync, then:
```bash
kubectl get pods -n dev
```
Pods should roll to `v2`.

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

- `p1`: `cd p1 && vagrant up && vagrant ssh <login>S -c "kubectl get nodes -o wide"`
- `p2`: `cd p2 && vagrant up && vagrant ssh <login>S -c "kubectl get all"` and curl tests to `192.168.56.110`
- `p3`: `p3/scripts/install_tools.sh`, `p3/scripts/setup_k3d_argocd.sh`, `kubectl get pods -n dev`
- `bonus`: `bonus/scripts/deploy_gitlab.sh`, `kubectl get pods -n gitlab`, then Argo CD + GitLab demo

---

> This README is for quick setup and validation. For full requirements, see `en.subject_v4.0.txt`.

<div align="center">⁂</div>
