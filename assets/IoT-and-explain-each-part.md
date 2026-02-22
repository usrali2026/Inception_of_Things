## 'IoT-and-explain-each-part.md`

```markdown
# Inception of Things (IoT) — Project Summary
**Login:** alrahmou | **Subject:** v4.0 | **Updated:** February 2026

Inception of Things (IoT) is a 42 School system administration project that serves as a
minimal introduction to Kubernetes, guiding you progressively from basic VM
orchestration to a full GitOps CI/CD pipeline.

---

## Overview

The project is structured into 3 mandatory parts (plus one optional bonus), each
building on the previous one. All work must be done inside virtual machines with
configuration files organized in `p1/`, `p2/`, `p3/`, and optionally `bonus/` at the
root of your Git repo.

---

## Part 1 — K3s and Vagrant

This part introduces the fundamentals of VM provisioning and lightweight Kubernetes.

- Provision **2 VMs** with a single `Vagrantfile` using the latest stable Linux distro
- VM 1 (`alrahmouS`) at `192.168.56.110` → K3s in **controller (server)** mode
- VM 2 (`alrahmouSW`) at `192.168.56.111` → K3s in **agent (worker)** mode
- Both VMs passwordless SSH accessible, minimal resources (1 CPU, 512–1024 MB RAM)
- Worker waits for server API readiness before joining — no manual token copy
- Verify healthy cluster: `kubectl get nodes -o wide` → both nodes `Ready`

---

## Part 2 — K3s and Three Web Apps

This part introduces Kubernetes Ingress routing with a single-node cluster.

- Only **1 VM** (`alrahmouS` at `192.168.56.110`) running K3s in server mode
- Deploy 3 web apps in the `webapps` namespace:
  - `app1-deployment` → 1 replica, accessible via `Host: app1.com`
  - `app2-deployment` → **3 replicas**, accessible via `Host: app2.com`
  - `app3-deployment` → 1 replica, **default backend** (no Host header)
- Traefik (bundled with K3s) handles Ingress routing based on HTTP `Host` header
- Test: `curl -H 'Host: app1.com' http://192.168.56.110` → app1

---

## Part 3 — K3d and Argo CD (GitOps)

The most complex part — a real continuous deployment pipeline without Vagrant.

- Install K3d + Docker + tools via `p3/scripts/install_k3d_argocd.sh`
- Create 2 namespaces: `argocd` (CD controller) and `dev` (deployed app)
- Connect Argo CD to GitHub repo: `https://github.com/usrali2026/Inception_of_Things.git`
- App image: `wil42/playground:v1` / `wil42/playground:v2` (pre-made, no login needed)
- GitOps flow: **push `v1→v2` to GitHub → Argo CD detects → auto-syncs → pod rolls over**
- Live demo:
  ```bash
  sed -i 's/wil42\/playground:v1/wil42\/playground:v2/' p3/dev-app/deployment.yaml
  git add . && git commit -m "v2" && git push
  # → Argo CD syncs → wil-playground pod updated to v2
```


---

## Bonus — GitLab Integration

Only evaluated if mandatory parts are **flawless**.

- Deploy self-hosted GitLab in K3d cluster in `gitlab` namespace via Helm
- Replace GitHub with local GitLab as Argo CD source — pipeline becomes self-contained:

```
Local GitLab (in K3d) → Argo CD (in K3d) → dev namespace (in K3d)
```

- App image: `alrahmou/playground:v1` / `alrahmou/playground:v2` (custom image)
- Argo CD `repoURL` uses internal cluster DNS:
`http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git`
- v1 → v2 switch via local GitLab push must trigger Argo CD sync cleanly

---

## Key Technologies at a Glance

| Part | Tool | Role |
| :-- | :-- | :-- |
| P1 | Vagrant + K3s | VM provisioning, multi-node cluster |
| P2 | K3s + Traefik Ingress | Single-node app routing |
| P3 | K3d + Argo CD + Docker Hub | GitOps CI/CD pipeline |
| Bonus | GitLab (self-hosted in K8s) | Local Git source for Argo CD |


---

## Vagrant (Part 1 \& 2)

Vagrant automates VM creation via a single declarative `Vagrantfile`. Key directives:

- `config.vm.define "alrahmouS"` / `"alrahmouSW"` → declares each VM
- `config.vm.network "private_network", ip: "..."` → static IP on host-only network
- `config.vm.provision "shell", path: "..."` → runs setup script on first boot
- `vagrant up` → spins up all VMs; `vagrant ssh alrahmouS` → passwordless access
- Libvirt network `iot56` (192.168.56.0/24) must exist before `vagrant up`

---

## K3s (Part 1 \& 2)

K3s is a lightweight, CNCF-certified Kubernetes distribution — single binary under
40 MB, replaces `etcd` with SQLite. Runs in two modes in this project:

- **Server mode** on `alrahmouS` — API server, scheduler, controller manager
- **Agent mode** on `alrahmouSW` — joins cluster via pre-shared token
`IOT42ClusterToken` passed from `Vagrantfile` → no manual token copy needed
- Config stored in `/etc/rancher/k3s/config.yaml` on each VM
- Both `k3s` and `k3s-agent` services must be **active AND enabled**

---

## K3d (Part 3)

K3d runs K3s entirely inside Docker containers instead of VMs — starts in seconds.


| Feature | K3s (Parts 1–2) | K3d (Part 3) |
| :-- | :-- | :-- |
| Runtime | Virtual Machine | Docker container |
| Speed | ~1–2 min | Seconds |
| Resource use | Slightly heavier | Lighter (shares kernel) |
| Use case | Simulates production VMs | Local dev, CI pipelines |
| Networking | VM private network | Docker bridge network |

Cluster name: `iot-p3` | Port mapping: `9080:80` (Bonus) | `--servers 1 --agents 1`

---

## Traefik Ingress Controller (Part 2)

Traefik is bundled with K3s and routes HTTP traffic based on Ingress YAML rules.
Routing logic for `alrahmouS` at `192.168.56.110`:

1. `curl -H 'Host: app1.com' http://192.168.56.110` → `app1-service`
2. `curl -H 'Host: app2.com' http://192.168.56.110` → `app2-service` (any of 3 replicas)
3. `curl http://192.168.56.110` (no Host) → **`app3-service`** (catch-all default)

Traefik watches the Kubernetes API live — no restarts needed when routes change.

---

## Argo CD (Part 3)

Argo CD is a Kubernetes-native GitOps CD tool — Git is the single source of truth.

GitOps flow in this project:

1. `p3/dev-app/deployment.yaml` in GitHub repo (`usrali2026/Inception_of_Things`) specifies `wil42/playground:v1`
2. Argo CD polls GitHub, detects drift between Git and live cluster
3. Drift → marks app **OutOfSync** → reconciles by applying new manifests
4. Pod in `dev` namespace rolls over to new image tag
5. UI shows **Synced + Healthy**

Verify:

```bash
kubectl get application -n argocd
# → dev-app   Synced   Healthy

kubectl get deployment -n dev \
  -o jsonpath='{.items.spec.template.spec.containers.image}'
# → wil42/playground:v2
```


---

## Docker Hub (Part 3 \& Bonus)

Docker Hub stores versioned container images Kubernetes pulls during deployments.

**Part 3** — uses pre-made image (no login requirement):

- `wil42/playground:v1` → `{"status":"ok","message":"v1"}`
- `wil42/playground:v2` → `{"status":"ok","message":"v2"}`

**Bonus** — uses custom image (repo name must include login):

- `alrahmou/playground:v1` → `{"status":"ok","message":"v1","author":"alrahmou"}`
- `alrahmou/playground:v2` → `{"status":"ok","message":"v2","author":"alrahmou","feature":"new_ui"}`

Both `:v1` and `:v2` tags must exist and be verifiable at:

- `hub.docker.com/r/wil42/playground/tags` (P3)
- `hub.docker.com/r/alrahmou/playground/tags` (Bonus)

---

## GitLab — Bonus

GitLab CE deployed inside K3d via Helm in the `gitlab` namespace. Key config:

- `gitlab-values.yaml` — disables certmanager, KAS, registry, runner (saves ~1GB RAM)
- `setup.sh` — installs all tools, deploys GitLab, registers repo in Argo CD automatically
- `argocd-app-gitlab.yaml` — `repoURL` uses internal cluster DNS (not GitHub)
- `cleanup_gitlab.sh` — full reset for clean defense retry

The fully self-contained pipeline:

```
Local GitLab (gitlab namespace)
       ↓  git push
Argo CD (argocd namespace)
       ↓  kubectl apply
dev namespace → alrahmou/playground:v2 running
```

```

***

## Updated `IoT_Evalsheet.md` (Personalized for alrahmou)

```markdown
# Inception-of-Things — Evaluation Checklist (v4.0)
**Login:** alrahmou | Last Updated: February 2026

---

## Preliminaries

Before starting:
- [ ] Defense can only happen if the evaluated group is present
- [ ] No empty work / wrong files / wrong directory / wrong filenames (grade = 0 if failed)
- [ ] Clone Git repository on the group's machine
- [ ] Ensure folders `p1/`, `p2/`, `p3/` exist at repo root (optional `bonus/`)

---

## Global — Explain in Simple Terms

- [ ] Basic operation of **K3s**
- [ ] Basic operation of **Vagrant**
- [ ] Basic operation of **K3d**
- [ ] What is **continuous integration** and **Argo CD**

---

## Part 1: K3s and Vagrant

### Configuration Checks
- [ ] `p1/Vagrantfile` exists and is understandable
- [ ] Exactly **2 VMs** defined
- [ ] Uses latest stable distro (**NOT** mandatory CentOS)
- [ ] IPs: `192.168.56.110` (server) and `192.168.56.111` (worker) — interface name may vary
- [ ] VM names: **`alrahmouS`** (Server) and **`alrahmouSW`** (ServerWorker)
- [ ] Scripts present: `p1/scripts/k3s_server.sh` and `p1/scripts/k3s_worker.sh`

> ⛔ If something doesn't work → evaluation stops here

### Usage Checks
- [ ] `vagrant ssh alrahmouS` — connects passwordlessly
- [ ] `vagrant ssh alrahmouSW` — connects passwordlessly
- [ ] Verify IP with `ip a` or `ip a show <interface>` (NOT ifconfig)
- [ ] Hostname `alrahmouS` correct on server
- [ ] Hostname `alrahmouSW` correct on worker
- [ ] K3s **server** mode on `alrahmouS`:
  ```bash
  sudo systemctl is-active k3s    # → active
  sudo systemctl is-enabled k3s   # → enabled
```

- [ ] K3s **agent** mode on `alrahmouSW`:

```bash
sudo systemctl is-active k3s-agent    # → active
sudo systemctl is-enabled k3s-agent   # → enabled
```

- [ ] `kubectl get nodes -o wide` on server → shows **both nodes**
- [ ] Both nodes: **STATUS: Ready**
- [ ] Correct INTERNAL-IPs: `192.168.56.110` and `192.168.56.111`
- [ ] Group explains the output

> ⛔ If something doesn't work → evaluation stops here

---

## Part 2: K3s and Three Simple Applications

### Configuration Checks

- [ ] Shut down P1 VMs first (avoid resource conflicts)
- [ ] `p2/Vagrantfile` exists — similar style to Part 1
- [ ] Only **1 VM** defined
- [ ] Uses latest stable distro
- [ ] IP: `192.168.56.110` — interface name may vary
- [ ] VM name: **`alrahmouS`**
- [ ] `p2/confs/apps-ingress.yaml` present
- [ ] Extra files in `p2/`? Ask for explanations

> ⛔ If something doesn't work → evaluation stops here

### Usage Checks

- [ ] `vagrant ssh alrahmouS` connects
- [ ] Verify IP with `ip a`
- [ ] Hostname: `alrahmouS`
- [ ] K3s in **server mode** only
- [ ] `kubectl get nodes -o wide` → `alrahmouS` + IP `192.168.56.110`
- [ ] `kubectl get all -n webapps`:
    - 3 deployments: `app1-deployment` (1), `app2-deployment` (3), `app3-deployment` (1)
    - 3 services: `app1-service`, `app2-service`, `app3-service`
    - **5 pods total** (1+3+1), all Running
- [ ] `kubectl -n kube-system get deploy,svc traefik` → Traefik running
- [ ] `kubectl -n webapps get ingress` → `webapps-ingress` with hosts `app1.com`, `app2.com`
- [ ] Group explains each output
- [ ] **Demonstrate Ingress works** (command NOT given — group must show it):

```bash
curl -H 'Host: app1.com' http://192.168.56.110    # → app1
curl -H 'Host: app2.com' http://192.168.56.110    # → app2
curl http://192.168.56.110                         # → app3 (default)
```


> ⛔ If something doesn't work → evaluation stops here

---

## Part 3: K3d and Argo CD

### Configuration Checks

- [ ] Start infrastructure with group's help: `bash p3/scripts/install_k3d_argocd.sh`
- [ ] Files present in `p3/` — explain each:
    - `p3/confs/argocd-app.yaml`
    - `p3/dev-app/deployment.yaml`
    - `p3/dev-app/service.yaml`
- [ ] Setup script: `p3/scripts/install_k3d_argocd.sh`
- [ ] 2 namespaces in K3d: `argocd` and `dev`

```bash
kubectl get ns   # → argocd Active, dev Active
```

- [ ] At least 1 pod in `dev` namespace:

```bash
kubectl get pods -n dev   # → wil-playground Running
```

- [ ] Group understands **difference between namespace and pod**
- [ ] All **7 Argo CD pods** running:

```bash
kubectl get pods -n argocd
# argocd-application-controller, argocd-applicationset-controller,
# argocd-dex-server, argocd-notifications-controller,
# argocd-redis, argocd-repo-server, argocd-server
```

- [ ] Argo CD accessible in browser with credentials (group provides):

```bash
# https://localhost:8080  |  admin / <password>
```

- [ ] GitHub repo name includes member login: **`usrali2026/Inception_of_Things`** ✅
- [ ] Docker image: `wil42/playground` (pre-made) ✅
- [ ] Both tags exist on Docker Hub: **`:v1`** and **`:v2`**
- [ ] `argocd-app.yaml` configured with:
    - `repoURL: https://github.com/usrali2026/Inception_of_Things.git`
    - `path: p3/dev-app`
    - Auto-sync enabled (`prune: true`, `selfHeal: true`)
- [ ] Extra files in `p3/`? Ask for explanations

> ⛔ If something doesn't work → evaluation stops here

### Usage Checks — The GitOps Flow

- [ ] Navigate Argo CD UI with group — understand how it works
- [ ] **⚠️ If explanations are confused → evaluation stops now (critical)**
- [ ] Application status:

```bash
kubectl get application -n argocd
# → dev-app   Synced   Healthy
```

- [ ] Verify **v1** running:

```bash
kubectl get deployment -n dev \
  -o jsonpath='{.items.spec.template.spec.containers.image}'
# → wil42/playground:v1
```

- [ ] Verify Docker Hub is used (if doubt → evaluation stops):

```bash
kubectl get pods -n dev -o yaml | grep imageID
# → docker.io/wil42/playground@sha256:...
```

- [ ] **Live v1 → v2 update** (group must explain the whole process):

```bash
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/' p3/dev-app/deployment.yaml
git add p3/dev-app/deployment.yaml
git commit -m "upgrade to v2"
git push
```

- [ ] After push — if auto-sync didn't happen, manually sync:

```bash
argocd app sync dev-app
```

- [ ] Verify successful sync:

```bash
kubectl get application dev-app -n argocd    # → Synced
kubectl get pods -n dev                       # → new v2 pod Running, v1 Terminating
```

- [ ] Confirm **v2** running (both commands):

```bash
kubectl get deployment -n dev \
  -o jsonpath='{.items.spec.template.spec.containers.image}'
# → wil42/playground:v2

kubectl get pod -n dev \
  -o jsonpath='{.items.spec.containers.image}'
# → wil42/playground:v2
```

- [ ] Rollback (optional but recommended):

```bash
# Change v2 → v1, commit, push → Argo CD syncs back to v1
```


> ⛔ If something doesn't work → evaluation stops now

---

## Bonus: GitLab Integration

> ⚠️ Only evaluate bonus if mandatory part is **flawless**

- [ ] Config files exist in `bonus/` — ask for explanations
- [ ] GitLab functions correctly (`http://localhost:8080` opens UI)
- [ ] GitLab deployed in cluster:

```bash
kubectl get pods -n gitlab   # → all Running
kubectl get ns               # → gitlab Active
```

- [ ] Create new repo `iot-app` in GitLab **live with evaluator**
- [ ] Push `deployment.yaml` + `service.yaml` to it — verify in GitLab UI
- [ ] Part 3 still works (`kubectl get pods -n argocd` → all Running)
- [ ] Argo CD uses **local GitLab** (not GitHub):

```bash
kubectl get application dev-app -n argocd -o yaml | grep repoURL
# → gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git
```

- [ ] GitLab repo contains **v1 and v2** versions (`alrahmou/playground:v1`, `:v2`)
- [ ] v1 → v2 sync via local GitLab push completes with no errors:

```bash
sed -i 's/alrahmou\/playground:v1/alrahmou\/playground:v2/' deployment.yaml
git add . && git commit -m "v2" && git push
# → Argo CD syncs → alrahmou/playground:v2 running in dev
```


> ✅ If synchronization works → validate bonus

---

## Final Ratings

- [ ] **Ok** — Mandatory complete
- [ ] **Outstanding** — Mandatory flawless + bonus works
- [ ] Empty work
- [ ] Incomplete work
- [ ] Cheat
- [ ] Crash
- [ ] Incomplete group
- [ ] Concerning situation
- [ ] Forbidden function

---

## Key Differences: Old Scale vs Subject v4.0

| Aspect | Old (CentOS) | New v4.0 |
| :-- | :-- | :-- |
| OS | CentOS mandatory | Distribution of your choice |
| Network check | `ifconfig eth1` | `ip a` or `ip a show <interface>` |
| Interface names | `eth0/eth1` expected | `enp0s8`, `enp0s9`, `eth1`, etc. |
| P2 namespace | Not specified | `webapps` expected |
| P3 structure | Generic | `p3/dev-app/` or `p3/k8s/dev/` |

```

***

## What Changed vs Original

| File | Changes |
|---|---|
| **Summary** | All `<login>` → `alrahmouS`/`alrahmouSW`; added `IOT42ClusterToken` note; P3 GitHub URL added; Docker Hub split into P3 (wil42) vs Bonus (alrahmou); Bonus fully rewritten with internal DNS URL; live demo `sed` command corrected with escaped slashes |
| **Evalsheet** | All `<login>` → `alrahmouS`/`alrahmouSW`; GitHub repo URL filled in; all verification commands added inline; Bonus section updated with `alrahmou/playground` image and internal GitLab DNS URL |
<span style="display:none">[^1][^2]</span>

<div align="center">⁂</div>

[^1]: summarize-IoT-and-explain-each-part.pdf
[^2]: IoT_Evalsheet.pdf```

