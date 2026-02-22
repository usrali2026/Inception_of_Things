Perfect! Here’s your **fully integrated, portfolio-ready README** for GitHub. It includes:

* **Interactive previews** for all PDFs/Markdown
* Full **P1–P3 + Bonus** sections
* **Pre-flight checks, troubleshooting, and resources**
* Clean, professional formatting suitable for evaluators or recruiters

You can copy this directly to `README.md` in the root of your repo.

---

````markdown id="final-readme"
# Inception-of-Things (IoT)

> Hands-on Kubernetes project for 42, demonstrating **K3s**, **K3d**, **Vagrant**, **Argo CD**, and optionally **GitLab**. Implements the official subject v4.0.  
> Login: **alrahmou**

> **Portfolio Summary:** Multi-environment IoT project showing Kubernetes clusters, GitOps automation, CI/CD with GitLab, and comprehensive evaluation documentation.

---

## 🚀 Project Structure

| Folder | Technology       | Purpose                                               |
|--------|-----------------|------------------------------------------------------|
| p1     | Vagrant + K3s    | 2-node K3s cluster (Server + ServerWorker VMs)       |
| p2     | Vagrant + K3s    | 1 K3s VM, 3 web apps, Traefik Ingress routing        |
| p3     | K3d + Argo CD    | GitOps: app in `dev` namespace, auto-synced via GitHub|
| bonus  | GitLab + Helm    | Self-hosted GitLab in K3d, Argo CD pulls from it     |
| assets | Docs & PDFs      | Evaluation sheets, defense commands, presentations   |
| assets/previews | PNG Previews | Inline thumbnails for GitHub display |

---

## 📄 Documentation & Evaluation (Interactive Previews)

Click images to open full PDFs or Markdown:

### IoT Evaluation Sheet
[![IoT Evaluation Sheet](assets/previews/IoT_Evalsheet.png)](assets/IoT_Evalsheet.pdf)

### Full Defense Command Sheets
**P1:** [![P1 Command Sheet](assets/previews/P1_Full_Defense_Command_Sheet.png)](assets/P1 Full Defense Command Sheet.pdf)  
**P2:** [![P2 Command Sheet](assets/previews/P2_Full_Defense_Command_Sheet.png)](assets/P2 Full Defense Command Sheet.md)  
**P3:** [![P3 Command Sheet](assets/previews/P3_Full_Defense_Command_Sheet.png)](assets/P3 Full Defense Command Sheet.pdf)

### Bonus Defense Sheet
[![Bonus Defense Sheet](assets/previews/Bonus_Full_Defense_Command_Sheet.png)](assets/Bonus Full Defense Command Sheet.pdf)

### IoT Explanation Markdown
[![IoT Explanation](assets/previews/IoT-and-explain-each-part.png)](assets/IoT-and-explain-each-part.md)

### Resource Management Awareness
[![Resource Awareness](assets/previews/resource-management-awareness.png)](assets/resource-management-awareness.md)

### Architecture Diagram
[![Cluster Architecture](assets/previews/architecture.png)](assets/previews/architecture.png)

---

## 🛠️ Prerequisites

- Host: ≥ 8 GB RAM, 4 vCPUs, 50 GB disk  
- Ubuntu 22.04+ or 24.04 host VM  
- Vagrant + vagrant-libvirt plugin (**libvirt recommended**)  
- Docker, kubectl, Git, libvirt + libvirt-dev  

**Installation Example:**

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant -y
sudo apt install libvirt-dev -y
vagrant plugin install vagrant-libvirt
sudo apt install docker.io -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
````

> **Note:** `[fog][WARNING] Unrecognized arguments: libvirt_ip_command` warnings are harmless.

---

## 🏗 Architecture Overview

* **Devices/Sensors** → Collect data
* **Edge Processing** → Local computations
* **Cloud/Server** → Centralized data management
* **GitLab CI/CD (Bonus)** → Automated deployments
* **Kubernetes / K3s + Argo CD** → Container orchestration and GitOps

![Cluster Architecture](assets/previews/architecture.png)

---

## 1️⃣ Part 1 – K3s & Vagrant (`p1`)

Spin up two VMs (Server + Worker) with K3s.

**Commands:**

```bash
cd p1
vagrant up
vagrant ssh alrahmouS   # Server validation
vagrant ssh alrahmouSW  # Worker validation
```

**Validation:**

```bash
kubectl get nodes -o wide
sudo systemctl is-active k3s
sudo systemctl is-enabled k3s
```

---

## 2️⃣ Part 2 – K3s + Apps + Ingress (`p2`)

Single VM with K3s, 3 web apps, Traefik Ingress.

**Commands:**

```bash
cd p2
vagrant up
kubectl get all -n webapps
kubectl get ingress -n webapps
```

**Demo:**

```bash
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl http://192.168.56.110  # Default app3
```

---

## 3️⃣ Part 3 – K3d + Argo CD (`p3`)

GitOps deployment with Argo CD.

**Commands:**

```bash
bash p3/scripts/install_k3d_argocd.sh
kubectl get application -n argocd
```

**Demo v1 → v2 Update:**

```bash
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/' p3/dev-app/deployment.yaml
git add p3/dev-app/deployment.yaml && git commit -m "upgrade to v2" && git push
argocd app sync dev-app
```

---

## ⭐ Bonus – GitLab Integration (`bonus`)

Self-hosted GitLab inside K3d, fully GitOps-compatible.

**Setup:**

```bash
bash bonus/scripts/setup.sh
```

Push manifests to GitLab, sync via Argo CD, demo live updates.

---

## 📋 Evaluation Checklist

* ✅ P1, P2, P3, and Bonus steps fully documented above
* ✅ Use `[x]` marks during defense to track completion

---

## 🔧 Troubleshooting

* libvirt network inactive → `virsh net-start iot56`
* Argo CD not syncing → `argocd app sync dev-app`
* Docker permissions → `sudo usermod -aG docker $USER`
* K3d cluster issues → `k3d cluster delete iot-p3 && bash p3/scripts/install_k3d_argocd.sh`

---

## 📚 Resources

* [K3s Docs](https://k3s.io/)
* [K3d Docs](https://k3d.io/)
* [Argo CD Docs](https://argo-cd.readthedocs.io/)
* [GitLab Helm Chart](https://docs.gitlab.com/charts/)
* [Vagrant libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)

---

> For full requirements see `en.subject_v4.0.pdf`.
> Evaluation checklist: `IoT_Evalsheet_UPDATED.pdf`.

```

---

This README now:

- Automatically displays **thumbnails for all PDFs/Markdown** in `assets/previews/`  
- Is fully **structured for portfolio presentation**  
- Includes **setup, validation, demos, troubleshooting, and resources**  

---

If you want, I can also create a **small script** that **automatically generates all PNG previews** from your PDFs and Markdown files, so you don’t need to manually screenshot anything — it will fully automate the portfolio setup.  

Do you want me to do that next?
``
