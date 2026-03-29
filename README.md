# Inception-of-Things (IoT)
> 42 School | K3s, K3d, Vagrant, ArgoCD, GitLab | Subject v4.0 | Login: alrahmou

## Part 1 — K3s and Vagrant
Two VMs via libvirt: alrahmouS (10.0.56.110, controller) + alrahmouSW (10.0.56.111, agent)
```bash
cd p1 && vagrant up --provider=libvirt
vagrant ssh alrahmouS -- kubectl get nodes -o wide
```

## Part 2 — K3s and Three Applications
Single VM, K3s server mode, Traefik Ingress routing:
- app1.com → app-one (1 replica)
- app2.com → app-two (3 replicas)
- default  → app-three
```bash
cd p2 && vagrant up --provider=libvirt
vagrant ssh default -- curl -H "Host: app1.com" http://10.0.56.110
vagrant ssh default -- curl -H "Host: app2.com" http://10.0.56.110
vagrant ssh default -- curl http://10.0.56.110
```

## Part 3 — K3d and ArgoCD
K3d cluster, ArgoCD watches GitHub, auto-deploys to dev namespace.
```bash
bash p3/scripts/install.sh
kubectl get app -n argocd
kubectl get pods -n dev
curl http://localhost:8888/
# v1→v2: edit p3/manifests/deployment.yaml, git push
```

## Bonus — Local GitLab + ArgoCD
GitLab runs in gitlab namespace inside K3d. ArgoCD watches local GitLab.
```bash
bash bonus/scripts/install.sh
kubectl get pods -n gitlab
kubectl get app -n argocd
curl http://localhost:8888/
# v1→v2: edit bonus/manifests/deployment.yaml, git push gitlab master
```

## Versions
Vagrant 2.4.3 | K3s v1.34.5 | K3d v5.8.3 | kubectl v1.35.3 | Helm v3.20.1 | GitLab v18.10.1
