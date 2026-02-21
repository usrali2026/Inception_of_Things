# Inception-of-Things (IoT)

> Hands-on Kubernetes project for 42, using **K3s**, **K3d**, **Vagrant**,
> **Argo CD**, and optionally **GitLab**. Implements the official subject v4.0.
> Login: **alrahmou**

---

## 🚀 Project Structure

| Folder | Technology       | Purpose                                               |
|--------|------------------|-------------------------------------------------------|
| p1     | Vagrant + K3s    | 2-node K3s cluster (Server + ServerWorker VMs)        |
| p2     | Vagrant + K3s    | 1 K3s VM, 3 web apps, Traefik Ingress routing         |
| p3     | K3d + Argo CD    | GitOps: app in `dev` namespace, auto-synced via GitHub|
| bonus  | GitLab + Helm    | Self-hosted GitLab in K3d, Argo CD pulls from it      |

All config lives under `p1/`, `p2/`, `p3/`, and optional `bonus/` at repo root.

---

## 🛠️ Prerequisites

**Host resources:** ≥ 8 GB RAM, 4 vCPUs, 50 GB disk

- Ubuntu 22.04+ or 24.04 host VM
- Vagrant + vagrant-libvirt plugin (**libvirt recommended**)
- Docker
- kubectl
- Git
- libvirt + libvirt-dev

**Installation:**

```bash
# 1. Install Vagrant
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant -y

# 2. Install vagrant-libvirt plugin
sudo apt install libvirt-dev -y
vagrant plugin install vagrant-libvirt

# 3. Install Docker
sudo apt install docker.io -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # logout + login after this

# kubectl and k3d are auto-installed by p3/scripts/install_k3d_argocd.sh
```

**Quick check:**

```bash
vagrant --version
docker --version
git --version
virsh --version
```

> **Note:** `[fog][WARNING] Unrecognized arguments: libvirt_ip_command` warnings
> are harmless — ignore them or suppress with the wrapper in `p1/vagrant-wrapper.sh`.

---

## ⚠️ Pre-flight (Run Before Any `vagrant up`)

```bash
# Confirm iot56 libvirt network is active — required for P1 and P2
virsh net-list --all
# Must show:
# iot56   active   yes

# If inactive:
virsh net-start iot56
```


---

## 1️⃣ Part 1 – K3s \& Vagrant (`p1`)

Spin up two VMs (Server + ServerWorker) with K3s using Vagrant.

**Folder:**

```
p1/
  Vagrantfile              # 2 VMs: alrahmouS (server) + alrahmouSW (worker)
  scripts/
    k3s_server.sh          # Installs K3s server mode, enables + starts k3s
    k3s_worker.sh          # Waits for server API, joins as agent, enables k3s-agent
  confs/                   # Empty — no config files required for P1
```

**Setup:**

```bash
# Run from repo root
cd p1
vagrant up
```

This will:

- Create `alrahmouS` at `192.168.56.110` → K3s **server (controller)** mode
- Create `alrahmouSW` at `192.168.56.111` → K3s **agent (worker)** mode
- Worker waits for server API to be ready before joining
- Both services explicitly enabled (active + enabled)

**Validation (inside VMs):**

```bash
# Connect to server
vagrant ssh alrahmouS

  hostname                                         # → alrahmouS
  ip a | grep 192.168.56.110                       # → correct IP
  sudo systemctl is-active k3s                     # → active
  sudo systemctl is-enabled k3s                    # → enabled
  kubectl get nodes -o wide
  # → alrahmouS    Ready   control-plane   192.168.56.110
  # → alrahmouSW   Ready   <none>          192.168.56.111

# Connect to worker (separate terminal)
vagrant ssh alrahmouSW

  hostname                                         # → alrahmouSW
  ip a | grep 192.168.56.111                       # → correct IP
  sudo systemctl is-active k3s-agent               # → active
  sudo systemctl is-enabled k3s-agent              # → enabled
```

**Useful commands:**

```bash
vagrant status                  # Check VM status
vagrant halt                    # Stop all VMs
vagrant destroy -f              # Delete all VMs
vagrant reload --provision      # Re-provision if something broke
```


---

## 2️⃣ Part 2 – K3s + 3 Apps + Ingress (`p2`)

Single VM with K3s, three web apps, and Traefik Ingress routing by Host header.

**Folder:**

```
p2/
  Vagrantfile                  # 1 VM: alrahmouS (192.168.56.110)
  scripts/
    install_k3s.sh             # Installs K3s, waits for Traefik, deploys apps
  confs/
    apps-ingress.yaml          # Namespace + 3 Deployments + 3 Services + Ingress
                               #   app1: 1 replica  → Host: app1.com
                               #   app2: 3 replicas → Host: app2.com
                               #   app3: 1 replica  → default backend (no Host)
```

**Setup:**

```bash
# Run from repo root
cd p2
vagrant up
```

This will:

- Create `alrahmouS` at `192.168.56.110` → K3s server mode
- Create `webapps` namespace
- Deploy 3 apps (5 pods total: 1+3+1)
- Configure Traefik Ingress with host-based routing

**Validation (inside VM):**

```bash
vagrant ssh alrahmouS

  hostname                                         # → alrahmouS
  ip a | grep 192.168.56.110                       # → correct IP
  sudo systemctl is-active k3s                     # → active
  sudo systemctl is-enabled k3s                    # → enabled

  kubectl get nodes -o wide
  # → alrahmouS   Ready   192.168.56.110

  kubectl get all -n webapps
  # → app1-deployment 1/1, app2-deployment 3/3, app3-deployment 1/1
  # → app1-service, app2-service, app3-service
  # → 5 pods total, all Running

  kubectl -n kube-system get deploy,svc traefik    # → Traefik running

  kubectl -n webapps get ingress
  # → webapps-ingress   traefik   app1.com,app2.com
```

**Ingress demo (from host machine — memorize these, evaluator won't give them):**

```bash
curl -H 'Host: app1.com' http://192.168.56.110    # → app1
curl -H 'Host: app2.com' http://192.168.56.110    # → app2
curl http://192.168.56.110                         # → app3 (default backend)
```


---

## 3️⃣ Part 3 – K3d + Argo CD (`p3`)

K3d cluster with Argo CD, deploying an app to the `dev` namespace from GitHub.
Demonstrates a full GitOps workflow with automatic synchronization.

**Folder:**

```
p3/
  scripts/
    install_k3d_argocd.sh    # Installs tools, creates cluster, deploys ArgoCD,
                             # applies Application manifest, auto-starts UI port-forward
  confs/
    argocd-app.yaml          # Argo CD Application:
                             #   repoURL: https://github.com/usrali2026/Inception_of_Things.git
                             #   path: p3/dev-app
                             #   namespace: dev
                             #   automated: prune=true, selfHeal=true
  dev-app/
    deployment.yaml          # image: wil42/playground:v1 (change to :v2 for demo)
    service.yaml             # ClusterIP on port 8888
```

**Setup:**

```bash
# Run from repo root (not from inside p3/)
bash p3/scripts/install_k3d_argocd.sh
```

This script will:

1. Install Docker (+ add user to docker group), kubectl, k3d, ArgoCD CLI
2. Create K3d cluster `iot-p3` (1 server + 1 agent)
3. Create namespaces: `argocd` and `dev`
4. Install Argo CD, wait for **all 7 pods** to be ready
5. Apply `p3/confs/argocd-app.yaml`
6. Auto-start ArgoCD UI port-forward on `https://localhost:8080`
7. Print admin credentials

**Validation:**

```bash
# Namespaces
kubectl get ns
# → argocd   Active
# → dev      Active

# All 7 ArgoCD pods Running
kubectl get pods -n argocd

# Application status
kubectl get application -n argocd
# → dev-app   Synced   Healthy

# App pod in dev
kubectl get pods -n dev
# → wil-playground-xxxx   1/1   Running

# Confirm v1 image
kubectl get deployment -n dev \
  -o jsonpath='{.items.spec.template.spec.containers.image}'
# → wil42/playground:v1

# ArgoCD UI
# → https://localhost:8080  |  admin / <password from script output>
```

**GitOps v1 → v2 demo:**

```bash
# Terminal 1 — watch rolling update in real time
watch kubectl get pods -n dev

# Terminal 2 — perform the update
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/' p3/dev-app/deployment.yaml
git add p3/dev-app/deployment.yaml
git commit -m "upgrade to v2"
git push

# If auto-sync doesn't trigger in ~30s:
argocd app sync dev-app

# Verify
kubectl get application dev-app -n argocd           # → Synced   Healthy
kubectl get deployment -n dev \
  -o jsonpath='{.items.spec.template.spec.containers.image}'
# → wil42/playground:v2
kubectl get pod -n dev \
  -o jsonpath='{.items.spec.containers.image}'
# → wil42/playground:v2

# Rollback (optional — do it, it's impressive)
sed -i 's/wil42\/playground:v2/wil42\/playground:v1/' p3/dev-app/deployment.yaml
git add p3/dev-app/deployment.yaml && git commit -m "rollback to v1" && git push
```

**Manual ArgoCD UI access (if port-forward died):**

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

**Cleanup:**

```bash
k3d cluster delete iot-p3
```


---

## ⭐ Bonus – GitLab Integration (`bonus`)

Self-hosted GitLab deployed inside K3d in the `gitlab` namespace via Helm.
Argo CD pulls from local GitLab instead of GitHub — fully self-contained pipeline.

**Folder:**

```
bonus/
  Complete Bonus Implementation Scripts and Configs.md
  confs/
    argocd-app-gitlab.yaml    # Argo CD Application pointing to local GitLab
                              #   repoURL: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git
                              #   name: dev-app
    gitlab-values.yaml        # Helm values: GitLab CE, no certmanager/KAS/registry/runner
    gitlab-default-values.yaml # Reference only — not used in deployment
    deployment.yaml           # image: alrahmou/playground:v1 → change to :v2 for demo
    service.yaml              # ClusterIP on port 8888
  scripts/
    setup.sh                  # Full automated setup: K3d + ArgoCD + GitLab + repo registration
    deploy_gitlab.sh          # Helm install/upgrade GitLab, port-forward to localhost:8080
    cleanup_gitlab.sh         # Full reset: kills port-forwards, uninstalls GitLab, deletes cluster
```

**Setup:**

```bash
# Run from repo root — takes 10-15 minutes
bash bonus/scripts/setup.sh
```

This script will:

1. Install Docker, kubectl, k3d, Helm, ArgoCD CLI
2. Create K3d cluster `iot-bonus` (port **9080** for loadbalancer, **not 8080**)
3. Create namespaces: `argocd`, `dev`, `gitlab`
4. Install Argo CD, wait for all 7 pods
5. Deploy GitLab via Helm with minimal CE config
6. Wait for GitLab webservice pod to be ready
7. Port-forward GitLab to `http://localhost:8080`
8. Register local GitLab repo in Argo CD (internal cluster DNS)
9. Print credentials for both GitLab and Argo CD

**After setup — manual steps (with evaluator):**

```bash
# 1. Create GitLab project
# → Open http://localhost:8080 | root / <password>
# → New Project → iot-app → Public → Create

# 2. Push app manifests to GitLab
git clone http://localhost:8080/root/iot-app.git
cd iot-app
cp ../bonus/confs/deployment.yaml .
cp ../bonus/confs/service.yaml .
git add . && git commit -m "feat: add v1 deployment" && git push

# 3. Apply Argo CD Application
kubectl apply -f bonus/confs/argocd-app-gitlab.yaml

# 4. Verify
kubectl get application -n argocd           # → dev-app   Synced   Healthy
kubectl get pods -n dev                      # → alrahmou-playground Running
```

**GitOps v1 → v2 demo (from local GitLab):**

```bash
cd iot-app
sed -i 's/alrahmou\/playground:v1/alrahmou\/playground:v2/' deployment.yaml
git add deployment.yaml && git commit -m "upgrade to v2" && git push

argocd app sync dev-app   # if auto-sync doesn't trigger

kubectl get deployment -n dev \
  -o jsonpath='{.items.spec.template.spec.containers.image}'
# → alrahmou/playground:v2
```

**Verify repo is local GitLab (not GitHub):**

```bash
kubectl get application dev-app -n argocd -o yaml | grep repoURL
# → repoURL: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git
```

**Cleanup:**

```bash
cd ..   # back to repo root
bash bonus/scripts/cleanup_gitlab.sh
```


---

## 📋 Evaluation Checklist

### Part 1

- [ ] `p1/Vagrantfile` — 2 VMs: `alrahmouS` + `alrahmouSW`
- [ ] IPs: `192.168.56.110` (server) and `192.168.56.111` (worker)
- [ ] `k3s` service: **active** AND **enabled** on server
- [ ] `k3s-agent` service: **active** AND **enabled** on worker
- [ ] `kubectl get nodes -o wide` → both nodes `Ready`, correct IPs
- [ ] `scripts/k3s_server.sh` + `scripts/k3s_worker.sh` present


### Part 2

- [ ] `p2/Vagrantfile` — 1 VM: `alrahmouS` at `192.168.56.110`
- [ ] `webapps` namespace created
- [ ] 3 deployments: `app1-deployment` (1), `app2-deployment` (3), `app3-deployment` (1)
- [ ] 3 services: `app1-service`, `app2-service`, `app3-service`
- [ ] 5 pods total, all `Running`
- [ ] Traefik running in `kube-system`
- [ ] `webapps-ingress` with hosts `app1.com`, `app2.com`
- [ ] `curl -H 'Host: app1.com' http://192.168.56.110` → app1
- [ ] `curl -H 'Host: app2.com' http://192.168.56.110` → app2
- [ ] `curl http://192.168.56.110` → app3 (default)


### Part 3

- [ ] K3d cluster `iot-p3` running
- [ ] Namespaces: `argocd` and `dev`
- [ ] 7 Argo CD pods all `Running`
- [ ] `dev-app` Application: `Synced` + `Healthy`
- [ ] Pod in `dev` namespace running `wil42/playground:v1`
- [ ] `repoURL` includes `usrali2026` login
- [ ] `path: p3/dev-app` in Application manifest
- [ ] Auto-sync: `prune: true`, `selfHeal: true`
- [ ] Live v1 → v2 switch works via `git push`
- [ ] Both `wil42/playground:v1` and `:v2` exist on Docker Hub


### Bonus

- [ ] Config files in `bonus/confs/` and `bonus/scripts/`
- [ ] GitLab running in `gitlab` namespace
- [ ] All 3 namespaces: `argocd`, `dev`, `gitlab`
- [ ] GitLab UI accessible at `http://localhost:8080`
- [ ] New repo `iot-app` created live with evaluator
- [ ] Manifests pushed to GitLab repo
- [ ] `argocd-app-gitlab.yaml` `repoURL` → internal GitLab DNS (not GitHub)
- [ ] `dev-app` Application: `Synced` + `Healthy`
- [ ] Live v1 → v2 switch via local GitLab push works

---

## 🔧 Troubleshooting

### libvirt network not found

```bash
virsh net-list --all          # check status
virsh net-start iot56         # start if inactive
```


### Vagrant fog warnings

```bash
# Use wrapper or add to ~/.zshrc:
vagrant() {
  local tmp=$(mktemp)
  command vagrant "$@" > "$tmp" 2>&1
  local code=$?
  grep -v "\[fog\]\[WARNING\] Unrecognized arguments: libvirt_ip_command" "$tmp"
  rm -f "$tmp"
  return $code
}
```


### Argo CD not syncing after git push

```bash
argocd app sync dev-app
# or force refresh:
kubectl annotate application dev-app -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
```


### K3d cluster issues

```bash
k3d cluster list
k3d cluster delete iot-p3
bash p3/scripts/install_k3d_argocd.sh   # recreate
```


### GitLab pod CrashLoopBackOff (Bonus)

```bash
kubectl get pods -n gitlab               # identify failing pod
kubectl describe pod <pod-name> -n gitlab
# Usually RAM: ensure host has ≥ 6GB free before starting bonus setup
free -h
```


### Docker permission denied (P3)

```bash
sudo usermod -aG docker $USER
# Then log out and back in, or:
exec sg docker bash
```


---

## 📚 Resources

- [K3s Documentation](https://k3s.io/)
- [K3d Documentation](https://k3d.io/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [GitLab Helm Chart](https://docs.gitlab.com/charts/)
- [Vagrant libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)

---

> For full requirements see `en.subject_v4.0.pdf`.
> Evaluation checklist: `IoT_Evalsheet_UPDATED.pdf`.
