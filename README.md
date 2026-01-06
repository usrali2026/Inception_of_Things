# 🚀 Inception of Things

<div align="center">

**A comprehensive Kubernetes learning project using K3s, K3d, Vagrant, and Argo CD**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![K3s](https://img.shields.io/badge/K3s-FF6A00?style=for-the-badge&logo=k3s&logoColor=white)](https://k3s.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white)](https://www.vagrantup.com/)

[![Status](https://img.shields.io/badge/status-active-success?style=flat-square)]()
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)]()

</div>

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [🎯 Project Overview](#-project-overview)
- [📦 Prerequisites](#-prerequisites)
- [🚀 Quick Start](#-quick-start)
- [📚 Detailed Documentation](#-detailed-documentation)
- [🏗️ Project Structure](#️-project-structure)
- [✅ Validation](#-validation)
- [🐛 Troubleshooting](#-troubleshooting)
- [🔒 Security](#-security)
- [📖 Additional Resources](#-additional-resources)

---

## ✨ Features

- 🖥️ **K3s Cluster Setup** - Automated VM provisioning with Vagrant
- 🌐 **Multi-App Deployment** - Three web applications with Ingress routing
- 🔄 **GitOps with Argo CD** - Automated application deployment and sync
- 🐳 **K3d Integration** - Lightweight Kubernetes for local development
- 🔧 **Complete Automation** - One-command deployment script
- 📝 **Comprehensive Docs** - Detailed guides and troubleshooting

---

## 🎯 Project Overview

This project is a **hands-on introduction to Kubernetes** using modern DevOps tools. It's designed to help you learn Kubernetes fundamentals through practical exercises.

### What You'll Learn

| Part | Technology | Description |
|------|-----------|-------------|
| **Part 1** | K3s + Vagrant | Set up a multi-node Kubernetes cluster using VMs |
| **Part 2** | K3s + Ingress | Deploy web applications with host-based routing |
| **Part 3** | K3d + Argo CD | Implement GitOps workflows with Argo CD |
| **Bonus** | Gitlab | Integrate Gitlab with your Kubernetes cluster |

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

### Required Tools

- 🐧 **Linux** host (or VM) with virtualization support
- 📦 **Vagrant** (tested with libvirt, VirtualBox also supported)
- 🐳 **Docker** (for K3d)
- ⚙️ **kubectl** (Kubernetes CLI)
- 📥 **Git**

### System Requirements

| Component | Minimum | Recommended |
|-----------|----------|-------------|
| **RAM** | 4GB | 8GB+ |
| **CPU** | 2 cores | 4+ cores |
| **Disk** | 20GB | 50GB+ |
| **Part 1 VMs** | 2GB RAM | 4GB RAM |
| **Part 3 (Docker)** | 2GB RAM | 4GB RAM |
| **Bonus (Gitlab)** | +4GB RAM | +8GB RAM |

### Verify Installation

```bash
# Check all prerequisites
vagrant --version
docker --version
kubectl version --client
git --version
```

---

## 🚀 Quick Start

### 🎬 Automated Deployment (Recommended)

Deploy everything with a single command:

```bash
# Clone the repository
git clone https://github.com/usrali2026/Inception_of_Things.git
cd Inception_of_Things

# Run automated deployment
./deploy_all.sh

# Or with bonus (Gitlab)
./deploy_all.sh --with-bonus
```

> 💡 **Tip**: The script automatically checks prerequisites and guides you through the process.

### 📖 Manual Deployment

#### Part 1: K3s Cluster Setup

```bash
cd p1
vagrant up
```

**Expected Output:**
```
✅ Server VM (wilS): 192.168.56.110
✅ Worker VM (wilSW): 192.168.56.111
✅ K3s cluster ready
```

#### Part 2: Deploy Applications

```bash
kubectl apply -f p2/app1-deployment.yaml
kubectl apply -f p2/app2-deployment.yaml
kubectl apply -f p2/app3-deployment.yaml
kubectl apply -f p2/ingress.yaml
```

**Access Applications:**
- 🌐 `http://app1.com` → App 1
- 🌐 `http://app2.com` → App 2 (3 replicas)
- 🌐 `http://192.168.56.110` → App 3 (default)

#### Part 3: K3d & Argo CD

```bash
cd p3
bash k3d-setup.sh
kubectl apply -f argocd-namespace.yaml
kubectl apply -f dev-namespace.yaml
# Update argocd-app.yaml with your repository URL
kubectl apply -f argocd-app.yaml
```

---

## 📚 Detailed Documentation

For comprehensive deployment guides and advanced topics:

| Document | Description |
|----------|-------------|
| 📘 [**DEPLOYMENT.md**](DEPLOYMENT.md) | Complete deployment guide with all options |
| ⚡ [**QUICK_START.md**](QUICK_START.md) | Quick reference for common commands |
| 📋 [**Inception-of-Things.md**](Inception-of-Things.md) | Original project requirements |

---

## 🏗️ Project Structure

```
Inception_of_Things/
│
├── 📁 p1/                          # Part 1: K3s & Vagrant
│   ├── 📄 Vagrantfile              # VM definitions
│   ├── 📁 scripts/
│   │   ├── setup_server.sh         # K3s server setup
│   │   └── setup_worker.sh         # K3s worker setup
│   └── 📁 confs/
│       └── node-token              # K3s join token (gitignored)
│
├── 📁 p2/                          # Part 2: Applications
│   ├── app1-deployment.yaml        # App 1 deployment
│   ├── app2-deployment.yaml        # App 2 deployment (3 replicas)
│   ├── app3-deployment.yaml        # App 3 deployment
│   └── ingress.yaml                # Ingress configuration
│
├── 📁 p3/                          # Part 3: K3d & Argo CD
│   ├── k3d-setup.sh               # K3d installation script
│   ├── argocd-namespace.yaml      # Argo CD namespace
│   ├── dev-namespace.yaml         # Dev namespace
│   └── argocd-app.yaml            # Argo CD application
│
├── 📁 bonus/                       # Bonus: Gitlab
│   ├── gitlab-namespace.yaml      # Gitlab namespace
│   └── gitlab-deployment.yaml     # Gitlab deployment guide
│
├── 🚀 deploy_all.sh                # Automated deployment script
├── 📖 README.md                    # This file
├── 📘 DEPLOYMENT.md                 # Detailed deployment guide
└── ⚡ QUICK_START.md                # Quick reference
```

---

## ✅ Validation

After deployment, verify everything is working:

```bash
# Check cluster nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get services --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces

# Check Argo CD applications
kubectl get applications -n argocd
```

### Expected Results

```
✅ All nodes in Ready state
✅ All pods running (Running status)
✅ Services accessible
✅ Ingress routes configured
✅ Argo CD applications synced
```

---

## 🐛 Troubleshooting

### Common Issues & Solutions

<details>
<summary><b>🔴 VMs Not Starting</b></summary>

**Problem**: Vagrant VMs fail to start

**Solutions**:
```bash
# Check virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo

# Check provider
vagrant status
vagrant up --provider=libvirt  # or virtualbox

# Destroy and recreate
vagrant destroy -f && vagrant up
```
</details>

<details>
<summary><b>🔴 kubectl Cannot Connect</b></summary>

**Problem**: `kubectl cluster-info` fails

**Solutions**:
```bash
# For K3s VM
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# For K3d
export KUBECONFIG=$(k3d kubeconfig write inception)

# Verify connection
kubectl cluster-info
```
</details>

<details>
<summary><b>🔴 Pods Not Starting</b></summary>

**Problem**: Pods stuck in `Pending` or `CrashLoopBackOff`

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check node resources
kubectl top nodes
```
</details>

<details>
<summary><b>🔴 Ingress Not Working</b></summary>

**Problem**: Cannot access applications via Ingress

**Solutions**:
```bash
# Add to /etc/hosts
sudo sh -c 'echo "192.168.56.110 app1.com app2.com" >> /etc/hosts'

# Check Ingress controller
kubectl get pods -n kube-system | grep traefik

# Verify Ingress resource
kubectl describe ingress apps-ingress
```
</details>

<details>
<summary><b>🔴 Argo CD Sync Fails</b></summary>

**Problem**: Argo CD application shows `SyncFailed`

**Solutions**:
```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Verify repository URL in argocd-app.yaml
# Ensure repository is accessible and has correct permissions
```
</details>

> 💡 **Need more help?** Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.

---

## 🔒 Security

### Best Practices

- ✅ **Sensitive Files**: Node tokens are excluded via `.gitignore`
- ✅ **No Hardcoded Secrets**: All credentials use environment variables
- ✅ **Resource Limits**: All deployments have CPU/memory limits
- ✅ **Health Checks**: Liveness and readiness probes configured

### Security Checklist

- [ ] Never commit sensitive credentials
- [ ] Use proper secret management for production
- [ ] Regularly update container images
- [ ] Review resource limits
- [ ] Enable network policies (production)

---

## 📖 Additional Resources

### Official Documentation

| Tool | Documentation |
|------|---------------|
| 🎯 [Kubernetes](https://kubernetes.io/docs/) | Official Kubernetes docs |
| 🚀 [K3s](https://docs.k3s.io/) | K3s documentation |
| 🐳 [K3d](https://k3d.io/) | K3d documentation |
| 🔄 [Argo CD](https://argo-cd.readthedocs.io/) | Argo CD documentation |
| 📦 [Vagrant](https://www.vagrantup.com/docs) | Vagrant documentation |

### Learning Resources

- 📚 [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- 🎓 [K3s Quick Start](https://docs.k3s.io/quick-start)
- 🔧 [Argo CD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is part of a System Administration course exercise.

---

<div align="center">

**Made with ❤️ for learning Kubernetes**

[⬆ Back to Top](#-inception-of-things)

</div>
