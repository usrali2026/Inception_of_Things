# Quick Start Guide - Kubernetes Deployment

## 🚀 Fastest Way to Deploy

```bash
# 1. Navigate to project directory
cd /devwork/apps/Inception_of_Things

# 2. Run automated deployment
./deploy_all.sh
```

That's it! The script handles everything.

---

## 📋 Step-by-Step Manual Deployment

### Part 1: K3s Cluster (Vagrant VMs)

```bash
cd p1
vagrant up
```

**Verify:**
```bash
vagrant ssh wilS -c "sudo kubectl get nodes"
```

### Part 2: Deploy Applications

**Option A: From host (if kubeconfig configured)**
```bash
kubectl apply -f p2/app1-deployment.yaml
kubectl apply -f p2/app2-deployment.yaml
kubectl apply -f p2/app3-deployment.yaml
kubectl apply -f p2/ingress.yaml
```

**Option B: From VM**
```bash
vagrant ssh wilS
sudo kubectl apply -f /vagrant/p2/*.yaml
```

### Part 3: K3d + Argo CD

```bash
cd p3
bash k3d-setup.sh
kubectl apply -f argocd-namespace.yaml
kubectl apply -f dev-namespace.yaml
# Edit argocd-app.yaml with your repo URL
kubectl apply -f argocd-app.yaml
```

---

## 🔍 Verification Commands

```bash
# Check cluster
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces

# Check Argo CD
kubectl get applications -n argocd
```

---

## 🌐 Access Applications

### Part 2 Apps (via Ingress)

1. **Add to /etc/hosts:**
   ```bash
   sudo sh -c 'echo "192.168.56.110 app1.com app2.com" >> /etc/hosts'
   ```

2. **Access:**
   - `http://app1.com` → app1
   - `http://app2.com` → app2
   - `http://192.168.56.110` → app3

### Argo CD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access: https://localhost:8080
# Username: admin
```

---

## 🛠️ Common Commands

### View Logs
```bash
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
```

### Describe Resources
```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
kubectl describe ingress <ingress-name>
```

### Delete Resources
```bash
kubectl delete -f p2/app1-deployment.yaml
kubectl delete deployment app1
kubectl delete namespace dev
```

### Scale Deployment
```bash
kubectl scale deployment app2 --replicas=5
```

### Port Forwarding
```bash
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80
```

---

## 🐛 Troubleshooting Quick Fixes

### kubectl can't connect
```bash
# For K3s VM
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# For K3d
export KUBECONFIG=$(k3d kubeconfig write inception)
```

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Ingress not working
```bash
kubectl get ingress
kubectl describe ingress apps-ingress
```

### Argo CD sync fails
```bash
kubectl describe application <app-name> -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

---

## 🧹 Cleanup

```bash
# Delete all deployments
kubectl delete -f p2/
kubectl delete -f p3/argocd-app.yaml

# Delete K3d cluster
k3d cluster delete inception

# Destroy Vagrant VMs
cd p1 && vagrant destroy -f
```

---

## 📚 More Information

- Full deployment guide: `DEPLOYMENT.md`
- Project overview: `README.md`
- Project requirements: `Inception-of-Things.md`

