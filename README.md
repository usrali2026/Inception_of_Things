

```markdown
# Inception of Things (42 – IoT)

Hands‑on Kubernetes project using **K3s**, **K3d**, **Vagrant**, and **Argo CD**, following the official Inception‑of‑Things subject (v4.0). [file:30]

---

## Project Overview

| Part   | Technology          | Description                                      |
|--------|---------------------|--------------------------------------------------|
| p1     | Vagrant + K3s       | 2‑node K3s cluster (server + worker) in VMs.    |
| p2     | Vagrant + K3s       | 1 K3s VM with 3 web apps + Ingress (host‑based).|
| p3     | K3d + Argo CD       | GitOps: app in `dev` namespace from GitHub.     |
| bonus  | GitLab + Helm       | Local GitLab, Argo CD pulling from GitLab repo. |

All configuration is under `p1/`, `p2/`, `p3/` and optional `bonus/` at the repo root, as required by the subject. [file:30]

---

## Prerequisites

On the **Ubuntu 22.04 host VM** where you run the project:

- Vagrant (with VirtualBox or libvirt provider). [file:30]
- Docker
- kubectl
- Git

Recommended host resources: at least **8 GB RAM**, 4 vCPUs, and ~50 GB free disk. [file:90]

Quick check:

```bash
vagrant --version
docker --version
kubectl version --client
git --version
```

---

## Part 1 – K3s and Vagrant (p1)

Two VMs with K3s: a server and a worker. [file:30]

**Structure:**

```text
p1/
  Vagrantfile
  scripts/
    setup_server.sh
    setup_worker.sh
  confs/
    node-token
```

**Run:**

```bash
cd p1
vagrant up
```

**Validate:**

```bash
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
```

Expected: 2 nodes (`alrahmouS`, `alrahmouSW`) with IPs `192.168.56.110` and `192.168.56.111`. [file:30][file:89]

---

## Part 2 – K3s + 3 apps + Ingress (p2)

One VM `alrahmouS` running K3s server with 3 apps and an Ingress routing by `Host` header. [file:30]

**Structure:**

```text
p2/
  Vagrantfile
  scripts/
    install_k3s_and_apps.sh
  confs/
    apps.yaml        # Deployments + Services for app1, app2 (3 replicas), app3
    ingress.yaml     # Ingress rules for app1.com, app2.com, default -> app3
```

**Run:**

```bash
cd p2
vagrant up
```

**Validate inside VM:**

```bash
vagrant ssh alrahmouS -c "kubectl get all"
```

Expected: 3 Deployments, 3 Services, 5 pods (3 for app2). [file:30][file:89]

**Test Ingress from host:**

```bash
curl -H "Host:app1.com" 192.168.56.110      # app1
curl -H "Host:app2.com" 192.168.56.110      # app2
curl -H "Host:whatever.com" 192.168.56.110  # app3 (default)
```

---

## Part 3 – K3d + Argo CD (p3)

K3d cluster on your Ubuntu VM with Argo CD deploying an app to the `dev` namespace from this GitHub repo. [file:30]

**Structure:**

```text
p3/
  scripts/
    install_tools.sh      # installs Docker, kubectl, k3d, argocd CLI
    setup_k3d_argocd.sh   # creates k3d cluster, namespaces, Argo CD, app
  confs/
    argocd-app.yaml       # Argo CD Application (repoURL + path)
  k8s/
    dev/
      deployment.yaml     # alrahmou-app (image v1/v2)
      service.yaml        # Service for alrahmou-app on port 8888
```

`argocd-app.yaml` points to:

```yaml
repoURL: "https://github.com/usrali2026/Inception_of_Things.git"
path: "p3/k8s/dev"
namespace: dev
```

**Run:**

```bash
p3/scripts/install_tools.sh
p3/scripts/setup_k3d_argocd.sh
```

**Validate:**

```bash
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
```

Expected: `argocd` and `dev` namespaces exist; `alrahmou-app` is running in `dev`. [file:30][file:89]

**Version switch demo:**

- In GitHub: edit `p3/k8s/dev/deployment.yaml` and change image tag from `v1` to `v2`, commit \& push.
- Wait for Argo CD to sync, then:

```bash
kubectl get pods -n dev
```

Pods should roll to `v2`, as in the subject example. [file:30]

---

## Bonus – GitLab integration (bonus)

Local GitLab deployed into `gitlab` namespace via Helm, used as a Git source for Argo CD instead of GitHub. [file:30]

**Structure:**

```text
bonus/
  confs/
    gitlab-namespace.yaml
  scripts/
    deploy_gitlab.sh
```

**Run:**

```bash
bonus/scripts/deploy_gitlab.sh
kubectl get ns
kubectl get pods -n gitlab
```

- GitLab UI exposed on `http://localhost:8080`.
- Create a project with manifests similar to `p3/k8s/dev` and configure an Argo CD `Application` to point to the GitLab repo URL.
- Repeat the v1→v2 image tag change from GitLab to show Argo CD syncs and updates the app. [file:30]

---

## Validation Cheat Sheet

- `p1`: `cd p1 && vagrant up && vagrant ssh alrahmouS -c "kubectl get nodes -o wide"`
- `p2`: `cd p2 && vagrant up && vagrant ssh alrahmouS -c "kubectl get all"` and curl tests to `192.168.56.110`.
- `p3`: `p3/scripts/install_tools.sh`, `p3/scripts/setup_k3d_argocd.sh`, `kubectl get pods -n dev`.
- `bonus`: `bonus/scripts/deploy_gitlab.sh`, `kubectl get pods -n gitlab`, then Argo CD + GitLab demo. [file:89]

This README is not required by the subject but helps evaluators run and understand your project quickly. [file:30]
<span style="display:none">[^3]</span>

<div align="center">⁂</div>

[^1]: README.md

[^2]: en.subject_v4.0.pdf

[^3]: TESTING_COMMANDS.md
