# Kubernetes Deployment Guide

This guide covers multiple ways to deploy the Inception-of-Things project to Kubernetes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Options](#deployment-options)
3. [Option 1: Automated Deployment (Recommended)](#option-1-automated-deployment-recommended)
4. [Option 2: Manual Deployment](#option-2-manual-deployment)
5. [Option 3: Deploy to Existing Kubernetes Cluster](#option-3-deploy-to-existing-kubernetes-cluster)
6. [Verification](#verification)
7. [Accessing Applications](#accessing-applications)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before deploying, ensure you have:

- **kubectl** installed and configured
- **Docker** installed (for K3d)
- **Vagrant** (for Part 1 with VMs)
- **Helm** (for Gitlab bonus section)
- Sufficient system resources

### Verify Prerequisites

```bash
# Check kubectl
kubectl version --client

# Check Docker
docker --version

# Check Vagrant (for Part 1)
vagrant --version

# Check Helm (for Gitlab)
helm version
```

---

## Deployment Options

This project supports three deployment scenarios:

1. **Full Automated Deployment**: Uses Vagrant VMs (K3s) + K3d + Argo CD
2. **Manual Step-by-Step**: Deploy each part individually
3. **Existing Cluster**: Deploy to your existing Kubernetes cluster

---

## Option 1: Automated Deployment (Recommended)

The easiest way to deploy everything:

### Quick Start

```bash
# Clone/navigate to project directory
cd /devwork/apps/Inception_of_Things

# Make scripts executable (if not already)
chmod +x deploy_all.sh p3/k3d-setup.sh

# Run automated deployment
./deploy_all.sh

# Or with bonus (Gitlab)
./deploy_all.sh --with-bonus
```

### What It Does

1. **Part 1**: Creates Vagrant VMs and installs K3s cluster
2. **Part 2**: Deploys three web applications with Ingress
3. **Part 3**: Sets up K3d cluster and Argo CD
4. **Bonus**: Optionally deploys Gitlab (if `--with-bonus` flag used)

### Prerequisites Check

The script automatically checks for:
- Vagrant
- kubectl
- Docker (for K3d)

---

## Option 2: Manual Deployment

Deploy each part individually for more control:

### Part 1: K3s Cluster with Vagrant

```bash
# Navigate to Part 1 directory
cd p1

# Start Vagrant VMs
vagrant up

# Verify VMs are running
vagrant status

# SSH into server to verify K3s
vagrant ssh wilS
sudo kubectl get nodes
exit

# Copy kubeconfig from server (optional, for local kubectl access)
vagrant ssh wilS -c "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig.yaml
# Update server IP in kubeconfig.yaml: replace 127.0.0.1 with 192.168.56.110
export KUBECONFIG=$(pwd)/kubeconfig.yaml
```

### Part 2: Deploy Applications

**If using Part 1 K3s cluster:**

```bash
# From host machine, connect to K3s cluster
# Set kubeconfig (see Part 1 above)

# Deploy applications
kubectl apply -f p2/app1-deployment.yaml
kubectl apply -f p2/app2-deployment.yaml
kubectl apply -f p2/app3-deployment.yaml
kubectl apply -f p2/ingress.yaml

# Wait for deployments to be ready
kubectl wait --for=condition=available deployment/app1 --timeout=120s
kubectl wait --for=condition=available deployment/app2 --timeout=120s
kubectl wait --for=condition=available deployment/app3 --timeout=120s
```

**Or deploy directly from VM:**

```bash
vagrant ssh wilS
sudo kubectl apply -f /vagrant/p2/app1-deployment.yaml
sudo kubectl apply -f /vagrant/p2/app2-deployment.yaml
sudo kubectl apply -f /vagrant/p2/app3-deployment.yaml
sudo kubectl apply -f /vagrant/p2/ingress.yaml
```

### Part 3: K3d and Argo CD

```bash
# Navigate to Part 3 directory
cd p3

# Run K3d setup script
bash k3d-setup.sh

# This script will:
# - Install Docker (if needed)
# - Install K3d
# - Create K3d cluster named "inception"
# - Install Argo CD

# Create namespaces
kubectl apply -f argocd-namespace.yaml
kubectl apply -f dev-namespace.yaml

# Update Argo CD application manifest with your repository
# Edit argocd-app.yaml and replace <your-org>/<your-repo>
nano argocd-app.yaml  # or use your preferred editor

# Apply Argo CD application
kubectl apply -f argocd-app.yaml
```

### Bonus: Gitlab Deployment

```bash
# Create namespace
kubectl apply -f bonus/gitlab-namespace.yaml

# Add Gitlab Helm repository
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Install Gitlab (adjust values as needed)
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email=your-email@example.com \
  --timeout 600s

# Wait for Gitlab to be ready
kubectl wait --for=condition=available deployment/gitlab-webservice-default -n gitlab --timeout=600s
```

---

## Option 3: Deploy to Existing Kubernetes Cluster

If you have an existing Kubernetes cluster (GKE, EKS, AKS, minikube, kind, etc.):

### Step 1: Verify Cluster Access

```bash
# Check cluster connection
kubectl cluster-info

# Verify nodes
kubectl get nodes
```

### Step 2: Deploy Part 2 Applications

```bash
# Deploy all applications
kubectl apply -f p2/app1-deployment.yaml
kubectl apply -f p2/app2-deployment.yaml
kubectl apply -f p2/app3-deployment.yaml
kubectl apply -f p2/ingress.yaml

# Note: Your cluster must have an Ingress controller installed
# For K3s/K3d: Traefik is included
# For other clusters: Install NGINX Ingress or similar
```

### Step 3: Deploy Argo CD (Optional)

```bash
# Create namespaces
kubectl apply -f p3/argocd-namespace.yaml
kubectl apply -f p3/dev-namespace.yaml

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Update and apply Argo CD application
# Edit p3/argocd-app.yaml with your repository details
kubectl apply -f p3/argocd-app.yaml
```

### Step 4: Access Argo CD UI

```bash
# Port forward to access Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Access UI at: https://localhost:8080
# Username: admin
# Password: (from command above)
```

---

## Verification

After deployment, verify everything is working:

### Check Cluster Status

```bash
# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get services --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces
```

### Check Specific Deployments

```bash
# Check Part 2 applications
kubectl get deployments
kubectl get pods -l app=app1
kubectl get pods -l app=app2
kubectl get pods -l app=app3

# Check Argo CD
kubectl get pods -n argocd
kubectl get applications -n argocd

# Check Gitlab (if deployed)
kubectl get pods -n gitlab
```

### Detailed Pod Information

```bash
# Describe a pod
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# For multi-container pods
kubectl logs <pod-name> -c <container-name>
```

---

## Accessing Applications

### Part 2 Applications (via Ingress)

**For K3s/K3d clusters:**

1. Add entries to `/etc/hosts`:
   ```bash
   sudo nano /etc/hosts
   ```
   Add:
   ```
   192.168.56.110 app1.com
   192.168.56.110 app2.com
   ```
   (For K3d, use `127.0.0.1` instead)

2. Access applications:
   - `http://app1.com` → app1
   - `http://app2.com` → app2 (3 replicas)
   - `http://192.168.56.110` → app3 (default)

**For existing clusters:**

Check your Ingress controller's external IP or use port-forwarding:

```bash
# Port forward ingress controller
kubectl port-forward -n kube-system svc/traefik 8080:80

# Or for NGINX Ingress
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

### Argo CD UI

```bash
# Port forward Argo CD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at: https://localhost:8080
# Username: admin
# Password: (get from secret)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Gitlab (if deployed)

```bash
# Port forward Gitlab
kubectl port-forward svc/gitlab-webservice-default -n gitlab 8080:80

# Access at: http://localhost:8080
# Get root password:
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d
```

---

## Troubleshooting

### Common Issues

#### 1. kubectl Cannot Connect to Cluster

**Problem**: `kubectl cluster-info` fails

**Solutions**:
```bash
# Check kubeconfig
kubectl config view

# Set correct kubeconfig
export KUBECONFIG=/path/to/kubeconfig.yaml

# For K3s VM, copy kubeconfig:
vagrant ssh wilS -c "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig.yaml
# Update server IP in kubeconfig.yaml

# For K3d:
export KUBECONFIG=$(k3d kubeconfig write inception)
```

#### 2. Pods Not Starting

**Problem**: Pods stuck in `Pending` or `CrashLoopBackOff`

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes

# Check pod resource requests
kubectl describe pod <pod-name> | grep -A 5 "Limits\|Requests"

# Check logs
kubectl logs <pod-name>
```

#### 3. Ingress Not Working

**Problem**: Cannot access applications via Ingress

**Solutions**:
```bash
# Check Ingress controller
kubectl get pods -n kube-system | grep traefik
# or
kubectl get pods -n ingress-nginx

# Check Ingress resource
kubectl describe ingress apps-ingress

# Verify Ingress controller service
kubectl get svc -n kube-system | grep traefik
```

#### 4. Argo CD Sync Fails

**Problem**: Argo CD application shows `SyncFailed`

**Solutions**:
```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Check Argo CD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Verify repository access
# Ensure repository URL is correct and accessible
# Check if repository requires authentication
```

#### 5. Docker/K3d Issues

**Problem**: K3d cluster creation fails

**Solutions**:
```bash
# Check Docker is running
docker info

# Check user is in docker group
groups | grep docker
# If not: sudo usermod -aG docker $USER
# Then: newgrp docker

# Remove existing cluster and retry
k3d cluster delete inception
k3d cluster create inception --port "8888:80@loadbalancer"
```

#### 6. Vagrant VM Issues

**Problem**: VMs not starting or network issues

**Solutions**:
```bash
# Check Vagrant status
vagrant status

# Destroy and recreate
vagrant destroy -f
vagrant up

# Check provider
vagrant up --provider=libvirt  # or virtualbox

# Check network conflicts
# Ensure IPs 192.168.56.110/111 are not in use
```

### Getting Help

- Check pod logs: `kubectl logs <pod-name>`
- Describe resources: `kubectl describe <resource> <name>`
- Check events: `kubectl get events --sort-by='.lastTimestamp'`
- Verify YAML syntax: `kubectl apply --dry-run=client -f <file.yaml>`

---

## Cleanup

To remove all deployments:

### Part 1 (Vagrant VMs)
```bash
cd p1
vagrant destroy -f
```

### Part 2 (Applications)
```bash
kubectl delete -f p2/app1-deployment.yaml
kubectl delete -f p2/app2-deployment.yaml
kubectl delete -f p2/app3-deployment.yaml
kubectl delete -f p2/ingress.yaml
```

### Part 3 (K3d and Argo CD)
```bash
# Delete K3d cluster
k3d cluster delete inception

# Or delete Argo CD resources
kubectl delete -f p3/argocd-app.yaml
kubectl delete namespace argocd dev
```

### Bonus (Gitlab)
```bash
# Uninstall Gitlab
helm uninstall gitlab -n gitlab
kubectl delete namespace gitlab
```

---

## Next Steps

After successful deployment:

1. **Explore Argo CD**: Set up GitOps workflows
2. **Customize Applications**: Modify deployment YAMLs
3. **Add Monitoring**: Integrate Prometheus/Grafana
4. **Set Up CI/CD**: Connect with Gitlab CI or GitHub Actions
5. **Scale Applications**: Test horizontal pod autoscaling

For more information, refer to:
- [K3s Documentation](https://docs.k3s.io/)
- [K3d Documentation](https://k3d.io/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

