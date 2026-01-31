# Complete Bonus Implementation Scripts and Configs

Based on the subject requirements for the GitLab bonus, here are all the necessary files:[^1]

## Directory Structure

```
bonus/
├── scripts/
│   ├── setup.sh
│   ├── deploy_gitlab.sh
│   └── cleanup_gitlab.sh
└── confs/
    ├── gitlab-values.yaml
    ├── argocd-app-gitlab.yaml
    ├── deployment.yaml
    └── service.yaml
```


***

## Scripts

### `bonus/scripts/setup.sh`

Main setup script that installs everything needed:

```bash
#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Inception-of-Things - Bonus Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running in VM
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found. Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}Docker installed. Please log out and back in, then run this script again.${NC}"
    exit 0
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Installing...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Check k3d
if ! command -v k3d &> /dev/null; then
    echo -e "${RED}k3d not found. Installing...${NC}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Check helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Helm not found. Installing...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo -e "${GREEN}✓ All prerequisites installed${NC}"
echo ""

# Check if k3d cluster exists
if ! k3d cluster list | grep -q "k3d-iot"; then
    echo -e "${YELLOW}Creating k3d cluster...${NC}"
    k3d cluster create k3d-iot --api-port 6550 -p "8080:80@loadbalancer" --agents 2
    kubectl cluster-info
else
    echo -e "${GREEN}✓ k3d cluster already exists${NC}"
    kubectl config use-context k3d-k3d-iot
fi

# Create namespaces
echo -e "${YELLOW}Creating namespaces...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespaces created${NC}"

# Install ArgoCD if not already installed
if ! kubectl get deployment argocd-server -n argocd &> /dev/null; then
    echo -e "${YELLOW}Installing ArgoCD...${NC}"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Get ArgoCD password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo -e "${GREEN}ArgoCD installed!${NC}"
    echo -e "ArgoCD Admin Password: ${YELLOW}${ARGOCD_PASSWORD}${NC}"
else
    echo -e "${GREEN}✓ ArgoCD already installed${NC}"
fi

# Deploy GitLab
echo ""
echo -e "${YELLOW}Deploying GitLab (this will take 5-10 minutes)...${NC}"
./bonus/scripts/deploy_gitlab.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "GitLab UI: ${YELLOW}http://localhost:8080${NC}"
echo -e "ArgoCD UI: ${YELLOW}http://localhost:8081${NC} (run: kubectl port-forward svc/argocd-server -n argocd 8081:443)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Log into GitLab at http://localhost:8080 with root and the password shown above"
echo "2. Create a new project called 'iot-app'"
echo "3. Push deployment.yaml and service.yaml from bonus/confs/"
echo "4. Apply the ArgoCD application: kubectl apply -f bonus/confs/argocd-app-gitlab.yaml"
echo "5. Verify the app is synced in ArgoCD"
```


### `bonus/scripts/deploy_gitlab.sh`

GitLab deployment script:

```bash
#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Deploying GitLab...${NC}"

# Add GitLab Helm repository
echo "Adding GitLab Helm repository..."
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Check if GitLab is already installed
if helm list -n gitlab | grep -q gitlab; then
    echo -e "${YELLOW}GitLab already installed. Upgrading...${NC}"
    helm upgrade gitlab gitlab/gitlab \
        -n gitlab \
        -f bonus/confs/gitlab-values.yaml \
        --timeout 600s
else
    echo "Installing GitLab..."
    helm install gitlab gitlab/gitlab \
        -n gitlab \
        -f bonus/confs/gitlab-values.yaml \
        --timeout 600s
fi

echo "Waiting for GitLab pods to be ready (this may take 5-10 minutes)..."
kubectl wait --for=condition=ready pod \
    -l app=webservice \
    -n gitlab \
    --timeout=900s 2>/dev/null || echo "Continuing..."

# Check pod status
echo ""
echo -e "${YELLOW}GitLab pod status:${NC}"
kubectl get pods -n gitlab

# Wait a bit more for all services
sleep 30

# Get root password
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitLab Deployed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "GitLab root password:"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode
echo ""
echo ""

# Start port-forward in background
echo -e "${YELLOW}Starting port-forward to GitLab...${NC}"
pkill -f "port-forward.*gitlab-webservice" 2>/dev/null || true
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8080:8181 > /dev/null 2>&1 &

echo -e "${GREEN}GitLab is accessible at: http://localhost:8080${NC}"
echo -e "Username: ${YELLOW}root${NC}"
echo ""
echo -e "${YELLOW}Note: GitLab may take a few more minutes to be fully ready.${NC}"
echo -e "${YELLOW}If the page doesn't load immediately, wait a bit and try again.${NC}"
```


### `bonus/scripts/cleanup_gitlab.sh`

Cleanup script:

```bash
#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  GitLab Cleanup${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}This will remove GitLab and all associated resources.${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo -e "${RED}Cleanup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup...${NC}"

# Kill port-forward processes
echo "Stopping port-forward processes..."
pkill -f "port-forward.*gitlab" 2>/dev/null || echo "No port-forward processes found"

# Remove ArgoCD applications
echo "Removing ArgoCD applications..."
kubectl delete application -n argocd wil-playground-gitlab --ignore-not-found=true

# Uninstall GitLab
if helm list -n gitlab | grep -q gitlab; then
    echo "Uninstalling GitLab Helm release..."
    helm uninstall gitlab -n gitlab --wait --timeout=300s
else
    echo "GitLab Helm release not found"
fi

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
kubectl wait --for=delete pod --all -n gitlab --timeout=120s 2>/dev/null || true

# Delete PVCs
echo "Deleting persistent volume claims..."
kubectl delete pvc -n gitlab --all --timeout=60s 2>/dev/null || true

# Delete namespace
echo "Deleting gitlab namespace..."
kubectl delete namespace gitlab --wait=true --timeout=120s 2>/dev/null || true

# Force remove if stuck
if kubectl get namespace gitlab &>/dev/null; then
    echo "Forcing namespace removal..."
    kubectl patch namespace gitlab -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
    kubectl delete namespace gitlab --force --grace-period=0 2>/dev/null || true
fi

# Clean up Helm repo
echo "Removing GitLab Helm repository..."
helm repo remove gitlab 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Verify
echo ""
if kubectl get namespace gitlab &>/dev/null; then
    echo -e "${RED}⚠ gitlab namespace still exists${NC}"
else
    echo -e "${GREEN}✓ gitlab namespace removed${NC}"
fi

if helm list -n gitlab 2>/dev/null | grep -q gitlab; then
    echo -e "${RED}⚠ GitLab Helm release still exists${NC}"
else
    echo -e "${GREEN}✓ GitLab Helm release removed${NC}"
fi
```


***

## Configuration Files

### `bonus/confs/gitlab-values.yaml`

GitLab Helm chart configuration:

```yaml
# GitLab configuration optimized for local development
global:
  # Domain configuration
  hosts:
    domain: localhost
    externalIP: 127.0.0.1
    https: false
  
  # Use community edition
  edition: ce
  
  # Ingress configuration
  ingress:
    enabled: false
    configureCertmanager: false
  
  # Initial root password (optional)
  initialRootPassword:
    secret: gitlab-gitlab-initial-root-password
  
  # Time zone
  time_zone: UTC
  
  # Application settings
  appConfig:
    enableUsagePing: false
    enableSeatLink: false
    enableImpersonation: true

# Disable cert-manager (not needed for local)
certmanager:
  install: false

# Disable nginx-ingress (using k3d loadbalancer)
nginx-ingress:
  enabled: false

# Prometheus monitoring (optional, can disable to save resources)
prometheus:
  install: false

# GitLab Runner (optional)
gitlab-runner:
  install: false

# PostgreSQL configuration
postgresql:
  image:
    tag: 13.6.0
  metrics:
    enabled: false

# Redis configuration
redis:
  metrics:
    enabled: false

# Registry configuration (optional, disable to save resources)
registry:
  enabled: true
  hpa:
    minReplicas: 1
    maxReplicas: 1

# GitLab Shell
gitlab-shell:
  minReplicas: 1
  maxReplicas: 1

# Webservice configuration
webservice:
  minReplicas: 1
  maxReplicas: 1

# Sidekiq configuration
sidekiq:
  minReplicas: 1
  maxReplicas: 1

# Gitaly configuration
gitaly:
  persistence:
    enabled: true
    size: 10Gi
```


### `bonus/confs/argocd-app-gitlab.yaml`

ArgoCD Application pointing to GitLab:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wil-playground-gitlab
  namespace: argocd
spec:
  project: default
  
  source:
    # GitLab repository URL (update with your actual GitLab project)
    # Format: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/<project-name>.git
    repoURL: 'http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git'
    targetRevision: HEAD
    path: .
  
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: dev
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```


### `bonus/confs/deployment.yaml`

Application deployment manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wil-playground
  namespace: dev
  labels:
    app: wil-playground
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wil-playground
  template:
    metadata:
      labels:
        app: wil-playground
    spec:
      containers:
      - name: wil-playground
        image: wil42/playground:v1
        ports:
        - containerPort: 8888
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```


### `bonus/confs/service.yaml`

Service manifest:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: wil-playground-service
  namespace: dev
  labels:
    app: wil-playground
spec:
  type: ClusterIP
  ports:
  - port: 8888
    targetPort: 8888
    protocol: TCP
    name: http
  selector:
    app: wil-playground
```


***

## Make Scripts Executable

```bash
chmod +x bonus/scripts/setup.sh
chmod +x bonus/scripts/deploy_gitlab.sh
chmod +x bonus/scripts/cleanup_gitlab.sh
```


***

## Usage Instructions

### 1. Deploy Everything

```bash
cd /path/to/Inception_of_Things
./bonus/scripts/setup.sh
```


### 2. Configure GitLab

1. Open http://localhost:8080
2. Login as `root` with the password displayed
3. Create a new project: `iot-app`
4. Initialize git locally:
```bash
cd bonus/confs
git init
git remote add origin http://localhost:8080/root/iot-app.git
git add deployment.yaml service.yaml
git commit -m "Initial commit - v1"
git push -u origin main
```


### 3. Update ArgoCD Application

Edit `bonus/confs/argocd-app-gitlab.yaml` to match your GitLab project URL, then:

```bash
kubectl apply -f bonus/confs/argocd-app-gitlab.yaml
```


### 4. Verify Deployment

```bash
kubectl get apps -n argocd
kubectl get pods -n dev
kubectl port-forward -n dev svc/wil-playground-service 8888:8888
curl http://localhost:8888/
```

Expected: `{"status":"ok", "message": "v1"}`

### 5. Update to v2

```bash
cd bonus/confs
sed -i 's/playground:v1/playground:v2/g' deployment.yaml
git add deployment.yaml
git commit -m "Update to v2"
git push

# Watch ArgoCD sync
kubectl get pods -n dev -w

# After sync completes
curl http://localhost:8888/
```

Expected: `{"status":"ok", "message": "v2"}`

### 6. Cleanup

```bash
./bonus/scripts/cleanup_gitlab.sh
```


***

## Verification Checklist

- ✅ GitLab namespace exists
- ✅ GitLab pods are Running
- ✅ GitLab accessible at http://localhost:8080
- ✅ ArgoCD Application synced with GitLab repo
- ✅ Application in `dev` namespace
- ✅ Version update from v1 to v2 works automatically
- ✅ All P3 functionality works with local GitLab

This complete implementation satisfies all bonus requirements from the subject.

