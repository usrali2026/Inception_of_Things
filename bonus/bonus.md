<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# bonus/confs/k3d-cluster.yaml  bonus/confs/argocd/install.yaml  bonus/confs/argocd/app.yaml                 bonus/confs/gitlab/values.yaml     bonus/confs/gitlab/storage.yaml    bonus/confs/app/deployment.yaml    bonus/confs/app/service.yaml                                   bonus/confs/app/ingress.yaml     bonus/confs/app/kustomization.yaml                         it is for a for 42 Inception_of_Things project: If you tell me your preferred distro (e.g. Ubuntu 22.04) and RAM/CPU budget, I can write out concrete content for 00_install_deps.sh and k3d-cluster.yaml next.

Below are concrete example contents for each of the listed files, assuming: Ubuntu 22.04 guest, k3d cluster named `iot-bonus`, and using Wil’s `playground` image (`wil42/playground`) with tags `v1` and `v2` on port 8888.[^1]

Adjust hostnames, repo URLs, and ports to your taste.

***

## `bonus/confs/k3d-cluster.yaml`

Minimal k3d config mapping host VM ports 80/443 to the cluster load balancer.[^2][^3]

```yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: iot-bonus
servers: 1
agents: 1

kubeAPI:
  host: "0.0.0.0"
  hostPort: "6443"

ports:
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer

# Optional: volume for persistence (GitLab PVs will still use the cluster's default StorageClass)
# volumes:
#   - volume: /var/lib/k3d-storage:/var/lib/rancher/k3s/storage
#     nodeFilters:
#       - all
```

You can then change `01_create_cluster.sh` to:

```bash
k3d cluster create --config /vagrant/bonus/confs/k3d-cluster.yaml
```


***

## `bonus/confs/argocd/install.yaml`

Wrapper kustomization that always pulls the official Argo CD install manifest.[^4][^5]

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

To use it instead of the URL in the script:

```bash
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -k /vagrant/bonus/confs/argocd/install.yaml
```


***

## `bonus/confs/argocd/app.yaml`

Argo CD `Application` pointing to your GitLab repo and deploying into `dev` namespace.[^1]

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: iot-app
  namespace: argocd
spec:
  project: default

  source:
    # CHANGE THIS to your actual GitLab project URL
    repoURL: http://gitlab.local/root/app-config.git
    targetRevision: main
    path: app

  destination:
    server: https://kubernetes.default.svc
    namespace: dev

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Here `path: app` assumes you put the manifests under `confs/app/` and pushed that directory as `app/` in the repo.

***

## `bonus/confs/gitlab/values.yaml`

Minimal GitLab Helm values for a single‑node dev install, exposed via NodePort (HTTP only) to keep things simple.[^6][^7]

```yaml
global:
  edition: ce

  hosts:
    domain: local
    https: false
    gitlab:
      name: gitlab.local

  ingress:
    configureCertmanager: false

  # Optional: if you create a custom StorageClass for GitLab PVs
  # See storage.yaml below
  # gitlab:
  #   rails:
  #     persistentVolume:
  #       storageClass: gitlab-storage

nginx-ingress:
  enabled: false

certmanager:
  install: false

prometheus:
  install: false

redis:
  install: true

postgresql:
  install: true

gitlab:
  webservice:
    service:
      type: NodePort
      nodePort: 32080    # HTTP on VM's node
  gitlab-shell:
    service:
      type: NodePort
      nodePort: 32222    # SSH (optional)

registry:
  enabled: false         # Save some resources for this lab
```

After install, GitLab will be reachable from inside the VM at `http://<node-ip>:32080` and, with `/etc/hosts` entry, as `http://gitlab.local:32080`.

***

## `bonus/confs/gitlab/storage.yaml` (optional)

If your k3d cluster already has a default `local-path` StorageClass, you can skip this file entirely.[^3][^2]
If you want a dedicated StorageClass for GitLab:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gitlab-storage
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
```

Then uncomment the `global.gitlab.rails.persistentVolume.storageClass` section in `values.yaml` so GitLab uses this class.

***

## `bonus/confs/app/deployment.yaml`

Deployment using Wil’s `playground` image on port 8888 with tag `v1` for the initial version, as in the subject.[^1]

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iot-app
  labels:
    app: iot-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: iot-app
  template:
    metadata:
      labels:
        app: iot-app
    spec:
      containers:
        - name: iot-app
          image: wil42/playground:v1
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8888
          readinessProbe:
            httpGet:
              path: /status
              port: 8888
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /status
              port: 8888
            initialDelaySeconds: 15
            periodSeconds: 10
```

During defense you change `v1` → `v2` in this file in GitLab to demonstrate the update via Argo CD.[^1]

***

## `bonus/confs/app/service.yaml`

ClusterIP service exposing the app on port 8888.[^1]

```yaml
apiVersion: v1
kind: Service
metadata:
  name: iot-app
  labels:
    app: iot-app
spec:
  type: ClusterIP
  selector:
    app: iot-app
  ports:
    - name: http
      port: 8888
      targetPort: 8888
```


***

## `bonus/confs/app/ingress.yaml`

Simple Ingress routing `http://app.local/` to the app’s service, assuming your k3d cluster has an ingress controller (Traefik by default in k3s/k3d).[^1]

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iot-app
  annotations:
    # Adjust to your ingress controller if needed
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: iot-app
                port:
                  number: 8888
```

On the VM, add to `/etc/hosts`:

```text
127.0.0.1 app.local
```

and access `http://app.local` via the k3d load balancer port 80.

***

## `bonus/confs/app/kustomization.yaml`

Kustomization bundling the three app resources together.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

If you want Argo CD to use kustomize, change the `Application` spec:

```yaml
source:
  repoURL: http://gitlab.local/root/app-config.git
  targetRevision: main
  path: app
  kustomize: {}
```

This set of files is enough to:

- Create the k3d cluster with mapped ports.
- Install ArgoCD from upstream manifests.
- Install GitLab via Helm with NodePort access.
- Deploy your app from a repo hosted on that local GitLab, with ArgoCD managing `v1` → `v2` changes.[^6][^4][^1]
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^8][^9]</span>

<div align="center">⁂</div>

[^1]: en.subject_v4.0.pdf

[^2]: https://gist.github.com/jei0486/e1b03d3d39c4e108d5c0e6ad52e31fdf

[^3]: https://github.com/k3d-io/k3d/discussions/821

[^4]: https://github.com/argoproj/argo-cd/blob/master/docs/getting_started.md

[^5]: https://argo-cd.readthedocs.io/en/stable/getting_started/

[^6]: https://docs.gitlab.com/charts/

[^7]: https://docs.gitlab.com/charts/charts/globals/

[^8]: https://git.lsgkerala.gov.in/help/install/kubernetes/gitlab_chart.md

[^9]: https://openreggui.org/git/help/install/kubernetes/gitlab_chart.md

[^10]: https://www.reddit.com/r/kubernetes/comments/pwh283/help_with_making_sense_out_of_gitlab_ingress/

[^11]: https://notes.kodekloud.com/docs/GitOps-with-ArgoCD/ArgoCD-Basics/ArgoCD-Installation

[^12]: https://www.reddit.com/r/kubernetes/comments/flpne4/how_to_set_custom_ingress_port_on_app_deployed/

[^13]: https://github.com/scaamanho/k3d-cluster

[^14]: https://github.com/nuttingd/gitlab-helm-chart/blob/master/doc/charts/globals.md

[^15]: https://github.com/argoproj/argo-cd/blob/master/manifests/README.md

[^16]: https://github.com/helm/charts/blob/master/stable/gitlab-ce/values.yaml

