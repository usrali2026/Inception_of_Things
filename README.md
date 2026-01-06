# Inception_of_Things

System Administration project focusing on Kubernetes, K3s, K3d, Vagrant, and Argo CD.

## Project Overview

This project is a comprehensive introduction to Kubernetes using lightweight distributions (K3s, K3d) and modern DevOps tools. It covers:

- **Part 1**: Setting up a K3s cluster using Vagrant VMs
- **Part 2**: Deploying web applications with Ingress routing
- **Part 3**: Using K3d for local development and Argo CD for GitOps
- **Bonus**: Gitlab integration

## Prerequisites

- Linux host (or VM) with virtualization support
- Vagrant (tested with libvirt provider, VirtualBox also supported)
- Docker (for K3d)
- kubectl
- Git
- Sufficient resources:
  - For Part 1: ~2GB RAM for VMs
  - For Part 3: Docker with sufficient resources
  - For Bonus: Additional resources for Gitlab

## Quick Start

### Automated Deployment

Run the deployment script to set up all parts:

```bash
./deploy_all.sh
```

For bonus section (Gitlab):
```bash
./deploy_all.sh --with-bonus
```

### Manual Setup

#### Part 1: K3s and Vagrant

```bash
cd p1
vagrant up
# VMs will be provisioned automatically
# Server: wilS (192.168.56.110)
# Worker: wilSW (192.168.56.111)
```

#### Part 2: K3s Applications

```bash
kubectl apply -f p2/app1-deployment.yaml
kubectl apply -f p2/app2-deployment.yaml
kubectl apply -f p2/app3-deployment.yaml
kubectl apply -f p2/ingress.yaml
```

Access applications:
- `app1.com` → app1
- `app2.com` → app2 (3 replicas)
- Default → app3

#### Part 3: K3d and Argo CD

```bash
cd p3
bash k3d-setup.sh
kubectl apply -f argocd-namespace.yaml
kubectl apply -f dev-namespace.yaml
# Update argocd-app.yaml with your repository URL
kubectl apply -f argocd-app.yaml
```

## Project Structure

```
Inception_of_Things/
├── p1/                    # Part 1: K3s and Vagrant
│   ├── Vagrantfile       # VM definitions
│   ├── scripts/          # Setup scripts
│   └── confs/            # Configuration files
├── p2/                    # Part 2: K3s Applications
│   ├── app1-deployment.yaml
│   ├── app2-deployment.yaml
│   ├── app3-deployment.yaml
│   └── ingress.yaml
├── p3/                    # Part 3: K3d and Argo CD
│   ├── k3d-setup.sh     # K3d installation script
│   ├── argocd-namespace.yaml
│   ├── dev-namespace.yaml
│   └── argocd-app.yaml
├── bonus/                 # Bonus: Gitlab
│   ├── gitlab-namespace.yaml
│   └── gitlab-deployment.yaml
├── deploy_all.sh         # Automated deployment script
└── README.md             # This file
```

## Validation

After deployment, verify the setup:

```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces

# Check services
kubectl get services --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces

# Check Argo CD applications
kubectl get applications -n argocd
```

## Troubleshooting

### Part 1 Issues

- **VMs not starting**: Check virtualization support and provider (libvirt/VirtualBox)
- **K3s token not found**: Ensure server VM completes setup before worker starts
- **Network issues**: Verify IP addresses (192.168.56.110/111) are not in use

### Part 2 Issues

- **Pods not starting**: Check resource limits and node capacity
- **Ingress not working**: Verify Traefik (K3s ingress controller) is running
- **Cannot access apps**: Add entries to `/etc/hosts`:
  ```
  192.168.56.110 app1.com
  192.168.56.110 app2.com
  ```

### Part 3 Issues

- **K3d cluster creation fails**: Ensure Docker is running and user is in docker group
- **Argo CD not accessible**: Check port forwarding and firewall rules
- **Application sync fails**: Verify repository URL and access permissions in argocd-app.yaml

## Security Notes

- Node tokens are stored in `p1/confs/node-token` (excluded from Git via .gitignore)
- Never commit sensitive credentials to the repository
- Use proper secret management for production deployments

## Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [K3d Documentation](https://k3d.io/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)

## License

This project is part of a System Administration course exercise.
