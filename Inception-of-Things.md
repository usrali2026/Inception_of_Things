# Inception-of-Things (IoT)

**Version:** 3.1

## Summary
This project is a System Administration exercise focused on Kubernetes, K3s, K3d, Vagrant, and Argo CD. It guides you through setting up virtual machines, deploying applications, and automating infrastructure using modern DevOps tools.

---

## Table of Contents
- [Preamble](#preamble)
- [Introduction](#introduction)
- [General Guidelines](#general-guidelines)
- [Mandatory Part](#mandatory-part)
  - [Part 1: K3s and Vagrant](#part-1-k3s-and-vagrant)
  - [Part 2: K3s and Three Simple Applications](#part-2-k3s-and-three-simple-applications)
  - [Part 3: K3d and Argo CD](#part-3-k3d-and-argo-cd)
- [Bonus Part](#bonus-part)
- [Submission and Peer-Evaluation](#submission-and-peer-evaluation)

---

## Preamble
This project aims to deepen your knowledge by making you use K3d and K3s with Vagrant. You will learn how to set up a personal virtual machine, use K3s and its Ingress, and discover K3d for simplified Kubernetes management.

## Introduction
This is a minimal introduction to Kubernetes. The project is designed to get you started with Kubernetes using K3s and K3d, but mastering Kubernetes requires further study.

## General Guidelines
- Complete the project in a virtual machine.
- Place all configuration files in folders at the root of your repository: `p1`, `p2`, `p3`, and optionally `bonus`.
- Read documentation as needed to learn K8s, K3s, and K3d.
- You may use any tools to set up your host VM and Vagrant provider.

## Mandatory Part
The project is divided into three required parts:

### Part 1: K3s and Vagrant
 Set up two VMs using Vagrant (1 CPU, 512–1024 MB RAM each).
 Machine names: `alrahmounS` (Server), `alrahmounSW` (ServerWorker).
 IPs: Server `192.168.56.110`, ServerWorker `192.168.56.111`.
 SSH access without password.
 Install K3s: Server in controller mode, ServerWorker in agent mode.
 Install and use `kubectl`.

**Example Vagrantfile:**
```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "<your_box>"
  config.vm.box_url = "<your_box_url>"

  config.vm.define "wilS" do |control|
    control.vm.hostname = "wilS"
    control.vm.network "private_network", ip: "192.168.56.110"
    control.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--name", "wilS"]
    end
    control.vm.provision "shell", path: "setup_server.sh"
  end

  config.vm.define "wilSW" do |control|
    control.vm.hostname = "wilSW"
    control.vm.network "private_network", ip: "192.168.56.111"
    control.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--name", "wilSW"]
    end
    control.vm.provision "shell", path: "setup_worker.sh"
  end
end
```

### Part 2: K3s and Three Simple Applications
- Use one VM with K3s in server mode.
- Deploy three web applications accessible via different HOST headers:
  - `app1.com` → app1
  - `app2.com` → app2 (with 3 replicas)
  - Default → app3
- Use Ingress to route requests.

### Part 3: K3d and Argo CD
- Install K3d (requires Docker).
- Write a script to install all required packages/tools.
- Create two namespaces: `argocd` and `dev`.
- Deploy an application in `dev` namespace via Argo CD using your public GitHub repo.
- Application must have two versions (e.g., v1 and v2) and be available on Dockerhub.
- Update the version via GitHub and verify deployment.

**Example commands:**
```bash
# Check namespaces
kubectl get ns

# Check pods in dev namespace
kubectl get pods -n dev

# Check deployed version
cat deployment.yaml | grep v1
curl http://localhost:8888/
```

---

## Bonus Part
- Add a local Gitlab instance to your lab (latest version).
- Create a `gitlab` namespace.
- Integrate Gitlab with your cluster and ensure all Part 3 features work with Gitlab.
- Place all bonus work in a `bonus` folder at the repo root.

---

## Submission and Peer-Evaluation
- Submit your assignment via your Git repository.
- Only work inside your repository will be evaluated.
- Mandatory part: folders `p1`, `p2`, `p3` at root.
- Bonus part: folder `bonus` at root (optional).

**Example directory structure:**
```bash
find -maxdepth 2 -ls
```

---

## Keywords
IoT, Kubernetes, K3s, K3d, Vagrant, Argo CD, Gitlab, DevOps, System Administration

---

_Last updated: 2025-11-05_
