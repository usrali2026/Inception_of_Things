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
- [🌍 Global Configuration and Explanation](#-global-configuration-and-explanation)

---

## ✨ Features

 - 🖥️ **K3s Cluster Setup** - Automated VM provisioning with Vagrant
 - 🌐 **Multi-App Deployment** - Three web applications with Ingress routing
 - 🔄 **GitOps with Argo CD** - Automated application deployment and auto-sync
 - 🐳 **K3d Integration** - Lightweight Kubernetes for local development
 - 🔧 **Complete Automation** - One-command deployment script (`deploy_all.sh`) with bonus Gitlab integration
 - 📝 **Comprehensive Docs** - Detailed guides, troubleshooting, and validation steps
 - 🛡️ **Security Best Practices** - No hardcoded secrets, `.gitignore` for sensitive files, resource limits, health checks
 - 🧪 **Validation & Compliance** - Automated checks, compliance review, and demonstration steps

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
| **RAM (host)** | 4GB | 8GB+ |
| **CPU (host)** | 2 cores | 4+ cores |
| **Disk** | 20GB | 50GB+ |
| **Part 1 VMs (each)** | 1 CPU, 512MB RAM<sup>†</sup> | 1 CPU, 1024MB RAM |
| **Part 3 (Docker)** | 2GB RAM | 4GB RAM |
| **Bonus (Gitlab)** | +4GB RAM | +8GB RAM |

<sup>†</sup> <sub>Subject minimum for each Vagrant VM: 1 CPU, 512MB RAM (or 1024MB). See project subject for details.</sub>

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

# Or with bonus (Gitlab integration)
./deploy_all.sh --with-bonus
```

> 💡 **Tip**: The script checks prerequisites, guides you, and validates each step. Bonus Gitlab integration is fully automated if prerequisites are met.

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
kubectl apply -f argocd-app.yaml
```

**Argo CD Workflow & Demonstration:**

- The application in `p3/manifests` is deployed and managed by Argo CD in the `dev` namespace.
- To update the app version:
	1. Edit `p3/manifests/deployment.yaml` and change the image tag (e.g., from `v1` to `v2`).
	2. Commit and push the change to your GitHub repository.
	3. Argo CD will automatically sync and update the deployment in your cluster.
- To test the running version:
	1. Port-forward the service:
		 ```
		 kubectl port-forward -n dev svc/sample-app 8890:8888
		 ```
	2. In another terminal, run:
		 ```
		 curl http://localhost:8890/
		 ```
		 You should see a response like `{ "status": "ok", "message": "v1" }` or `"v2"` depending on the deployed version.
- For evaluation, demonstrate:
	- Argo CD application status is **Synced** and **Healthy** (`kubectl get applications -n argocd`)
	- Pod status in the dev namespace (`kubectl get pods -n dev`)
	- Version update by changing the image tag, committing, pushing, and verifying with curl as above.
- Make your repository public before evaluation so Argo CD can access it.

---

## 📚 Detailed Documentation
See [DEPLOYMENT.md](DEPLOYMENT.md), [QUICK_START.md](QUICK_START.md), and folder-level READMEs for:
- Step-by-step manual deployment
- Argo CD workflow and demonstration
- Gitlab integration and CI/CD pipeline
- Validation and troubleshooting
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
│   ├── argocd-app.yaml            # Argo CD application
│   └── manifests/                 # App manifests for Argo CD
│
├── 📁 bonus/                       # Bonus: Gitlab
│   ├── gitlab-namespace.yaml      # Gitlab namespace
│   ├── gitlab-deployment.yaml     # Gitlab deployment guide
│   ├── deploy_gitlab.sh           # Gitlab automation script
│   └── .gitlab-ci.yml             # Sample Gitlab CI/CD pipeline
│
├── 🚀 deploy_all.sh                # Automated deployment script (supports --with-bonus)
├── 📖 README.md                    # This file
├── 📘 DEPLOYMENT.md                # Detailed deployment guide
├── ⚡ QUICK_START.md                # Quick reference
└── 📝 COMPLIANCE_REVIEW.md          # Compliance and validation summary
```

---


## ✅ Validation & Testing

Follow these steps to validate and demonstrate each part of the project. All commands are to be run from the root of the repository unless otherwise specified.

### Part 1: K3s and Vagrant

#### Configuration Check
- Ensure `p1/Vagrantfile` exists and defines two VMs: `alrahmouS` and `alrahmouSW`.
- VM resources: 1 CPU, 1024MB RAM each.
- Network interface (enp0s8) IPs: 192.168.56.110 (alrahmouS), 192.168.56.111 (alrahmouSW).
- Hostnames: alrahmouS and alrahmouSW.
- SSH is passwordless. K3s install scripts present.

#### Usage & Validation
```sh
cd p1
vagrant up
vagrant status
vagrant ssh alrahmouS -c "echo 'Connected to alrahmouS'"
vagrant ssh alrahmouSW -c "echo 'Connected to alrahmouSW'"
vagrant ssh alrahmouS -c "ip addr show eth1 | grep 'inet '"
vagrant ssh alrahmouSW -c "ip addr show eth1 | grep 'inet '"
vagrant ssh alrahmouS -c "hostname"
vagrant ssh alrahmouSW -c "hostname"
vagrant ssh alrahmouS -c "k3s --version || k3s -v"
vagrant ssh alrahmouSW -c "k3s --version || k3s -v"
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
```

---

### Part 2: Application Deployment

#### Configuration Check
- Ensure `p2/` contains `app1-deployment.yaml`, `app2-deployment.yaml`, `app3-deployment.yaml`, `ingress.yaml`.
- Check each manifest for correct app name, image, and replica count (app2: 3 replicas).
- Verify ingress rules for app1.com, app2.com, and default to app3.

#### Usage & Validation
```sh
vagrant ssh alrahmouS -c "kubectl get nodes -o wide"
vagrant ssh alrahmouS -c "kubectl get all -n kube-system"
vagrant ssh alrahmouS -c "kubectl get deployments -n default"
vagrant ssh alrahmouS -c "kubectl get pods -n default"
vagrant ssh alrahmouS -c "kubectl get ingress -n default"
vagrant ssh alrahmouS -c "curl -H 'Host: app1.com' http://192.168.56.110"
vagrant ssh alrahmouS -c "curl -H 'Host: app2.com' http://192.168.56.110"
vagrant ssh alrahmouS -c "curl -H 'Host: app3.com' http://192.168.56.110"
```

---

### Part 3: K3d & Argo CD

#### Configuration Check
- Ensure `p3/` contains `argocd-app.yaml`, `argocd-namespace.yaml`, `dev-namespace.yaml`, `manifests/`, `k3d-setup.sh`.
- Check `argocd-app.yaml` for correct repoURL, path, and syncPolicy.
- Verify Docker image names and tags (v1, v2) in manifests.

#### Usage & Validation
```sh
cd p3
./k3d-setup.sh
kubectl get ns # Should list 'argocd' and 'dev'
kubectl get pods -n dev
kubectl get svc --all-namespaces
kubectl get pods -n argocd
# Access Argo CD UI in browser (URL and credentials provided by group)
# Confirm your repo name includes your login (e.g., usrali2026/Inception_of_Things)
# Confirm your Docker image is named with your login and has v1 and v2 tags on Docker Hub
# Edit manifest to v2, commit/push, sync in Argo CD, verify update
```

---

### Bonus: Gitlab Integration

#### Configuration Check
- Ensure `bonus/` contains Gitlab deployment/configuration files.
- Check `gitlab-namespace.yaml`, `gitlab-deployment.yaml`, and integration steps.

#### Usage & Validation
```sh
# Create a new repository, add code, verify in Gitlab UI.
# Use Gitlab repo in Argo CD, repeat application update workflow.
# If sync and version change work, bonus is validated.
```

---

### General Validation Commands
```sh
# Validate Vagrantfile
vagrant validate
# Validate Kubernetes manifests
yamllint p1/ p2/ p3/
# Check shell scripts
shellcheck *.sh
# Test cluster setup
kubectl get ns
kubectl get pods -n dev
# Argo CD sync status
argocd app list
# Gitlab deployment (bonus)
kubectl get pods -n gitlab
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

#### Expected Results
```
✅ All nodes in Ready state
✅ All pods running (Running status)
✅ Services accessible
✅ Ingress routes configured
✅ Argo CD applications synced
```

See [COMPLIANCE_REVIEW.md](COMPLIANCE_REVIEW.md) for the full checklist and evidence.

---

## 🐛 Troubleshooting
See [QUICK_START.md](QUICK_START.md) and folder-level READMEs for troubleshooting tips, common errors, and quick fixes.
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
- ✅ Sensitive files excluded via `.gitignore`
- ✅ No hardcoded secrets; use environment variables
- ✅ Resource limits and health checks on all deployments
- ✅ Security scan and validation for all infrastructure code

### Security Checklist
- [ ] Never commit sensitive credentials
- [ ] Use proper secret management for production
- [ ] Regularly update container images
- [ ] Review resource limits
- [ ] Enable network policies (production)

---

## 📖 Additional Resources
See also:
- [bonus/README.md](bonus/README.md) for Gitlab integration and CI/CD pipeline details
- [p3/manifests/README.md](p3/manifests/README.md) for Argo CD demonstration and workflow
- [COMPLIANCE_REVIEW.md](COMPLIANCE_REVIEW.md) for compliance evidence and validation
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

---

## 🌍 Global Configuration and Explanation

Those being evaluated should be able to explain simply:

### Basic Operation of K3s
K3s is a lightweight Kubernetes distribution designed for resource-constrained environments and edge computing. It simplifies Kubernetes installation and management, making it ideal for learning and small-scale deployments. K3s includes all the essential Kubernetes components and can run on a single VM or multiple nodes.

### Basic Operation of Vagrant
Vagrant is a tool for building and managing virtual machine environments. It uses simple configuration files (Vagrantfile) to automate VM creation, provisioning, and networking. Vagrant helps ensure consistent development environments and is widely used for testing infrastructure setups.

### Basic Operation of K3d
K3d is a utility that runs K3s clusters inside Docker containers. It allows rapid creation and management of Kubernetes clusters locally, making it perfect for development and CI/CD pipelines. K3d leverages Docker for isolation and resource management.

### What is Continuous Integration and Argo CD
Continuous Integration (CI) is a development practice where code changes are automatically built, tested, and integrated into shared repositories. This ensures rapid feedback and higher code quality. Argo CD is a GitOps tool for Kubernetes that automates application deployment and synchronization from a Git repository. It continuously monitors the repository and applies changes to the cluster, enabling automated, declarative, and auditable deployments.
