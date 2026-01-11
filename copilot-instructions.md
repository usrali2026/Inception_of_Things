

# Copilot Instructions for Inception-of-Things

This guide provides all requirements and actionable steps for implementing the Inception-of-Things project using GitHub Copilot. It covers environment setup, folder structure, step-by-step deliverables, validation, and prompt templates for each technology (Vagrant, K3s, K3d, Argo CD, Gitlab).



## Quick Rules

- Use Copilot for small, well-scoped tasks: config files, scripts, test cases, YAML manifests, and documentation.
- For infrastructure (Vagrantfile, K3s/K3d manifests, Argo CD configs), always cross-check generated code with official docs.
- Never accept large, complex PRs generated entirely by Copilot without careful review and testing.
- Always run tests, linters, and type-checking locally before committing Copilot-generated code.
- Do not expose secrets, credentials, private keys, or any PII in prompts or generated code.



## Project Requirements & Setup

### 1. Folder Structure
- At repo root, create:
	- `p1/` for Vagrant and K3s setup
	- `p2/` for K3s and three web apps
	- `p3/` for K3d and Argo CD
	- `bonus/` for Gitlab integration (optional)

### 2. Environment Setup
- Use a Linux host or VM for development.
- Install Vagrant, VirtualBox (or provider), Docker, kubectl, K3s, K3d, Argo CD CLI, Gitlab (for bonus).
- Validate each tool is installed:
	```bash
	vagrant --version
	docker --version
	kubectl version --client
	k3d version
	argocd version
	```

### 3. Step-by-Step Implementation

#### Part 1: Vagrant & K3s
	> "Write a Vagrantfile for two VMs named wilS and wilSW, with IPs 192.168.56.110/111, SSH access, and K3s installed as described in Inception-of-Things.md."
 Write a Vagrantfile for two VMs (`alrahmounS`, `alrahmounSW`) with dedicated IPs, SSH access, and minimal resources (1 CPU, 512–1024 MB RAM).
 Provision K3s: Server in controller mode, ServerWorker in agent mode.
 Install and configure `kubectl` on both VMs.
 Example Copilot prompt:

#### Part 2: K3s & Three Web Apps
- Use one VM with K3s in server mode.
- Deploy three web applications (app1, app2 with 3 replicas, app3 default) using Kubernetes manifests.
- Configure Ingress to route requests by HOST header.
- Example Copilot prompt:
	> "Generate Kubernetes deployment and Ingress YAML for three web apps, routing by HOST header as described in the project."

#### Part 3: K3d & Argo CD
- Install K3d (requires Docker).
- Create two namespaces: `argocd` and `dev`.
- Deploy an application in `dev` via Argo CD, using a public GitHub repo and Docker image (with tags v1, v2).
- Automate version updates via GitHub and verify deployment.
- Example Copilot prompt:
	> "Create an Argo CD application manifest for a Docker image with two tags, supporting automated updates."

#### Bonus: Gitlab Integration
- Deploy Gitlab in a dedicated namespace using Helm or manifest.
- Integrate Gitlab with your cluster and ensure all Part 3 features work with Gitlab.
- Place all bonus work in `bonus/`.
- Example Copilot prompt:
	> "Write a manifest to deploy Gitlab in a dedicated namespace and integrate with K3d."


## How to Prompt Copilot for This Project

- For Vagrantfile: "Write a Vagrantfile for two VMs named wilS and wilSW, with dedicated IPs and SSH access, following the specs in Inception-of-Things.md."
- For K3s/K3d manifests: "Generate a Kubernetes deployment YAML for three web apps, with Ingress routing based on HOST header as described in the project."
- For Argo CD: "Create an Argo CD application manifest that deploys a Docker image from GitHub, with two versions (v1, v2), and supports automated updates."
- For Gitlab: "Write a Helm chart or manifest to deploy Gitlab in a dedicated namespace, integrated with an existing K3d cluster."
- For tests: "Generate shell scripts or kubectl commands to verify namespace, pod status, and application version as shown in the README."


## Code Style and Commits

- Match the style for each technology (Ruby for Vagrantfile, YAML for K8s, Bash for scripts).
- Use formatters/linters where available (e.g., `yamllint`, `shellcheck`).
- Commit messages for Copilot-assisted work should indicate assistance, e.g., `chore: add K3s manifest (Copilot)`.


## Security and Secrets

- Never paste secrets, private tokens, or hostnames into prompts. Use environment variables or secret management instead.
- If Copilot suggests credentials or keys, remove them and replace with secure references.
- For infrastructure code, ensure no hardcoded secrets in Vagrantfile, manifests, or scripts.
- For dependency changes, run security scans and request manual approval from a maintainer.


## Review Checklist (Before Merging Copilot-Assisted PRs)

1. Tests: New/changed behavior covered by automated tests or manual validation (VM, cluster, etc.).
2. Lint/Format: Code passes linters/formatters (`yamllint`, `shellcheck`, etc.).
3. Minimal Scope: PR is focused and small; split large features into smaller PRs.
4. Security: No secrets or insecure patterns introduced; dependency updates reviewed.
5. Infrastructure: All manifests, Vagrantfiles, and scripts validated in a test environment.
6. Performance: No unnecessary resource usage in VM specs or K8s manifests.

If any item fails, request changes or rewrite the suspect portion without Copilot assistance.



## Validation / How to Run Checks Locally

Run these checks before merging Copilot-generated code:
```bash
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
```
Replace or extend these commands with the actual tooling/scripts in your repo.



## Example Copilot Prompts for Each Deliverable

- Vagrantfile: "Write a Vagrantfile for two VMs with hostnames wilS and wilSW, IPs 192.168.56.110/111, SSH access, and K3s installed."
- K3s manifest: "Create Kubernetes deployments for three web apps, with Ingress routing by HOST header."
- Argo CD: "Generate an Argo CD application manifest for a Docker image with tags v1 and v2, supporting automated updates."
- Gitlab: "Write a manifest to deploy Gitlab in a dedicated namespace and integrate with K3d."
- Test script: "Write a shell script to check pod status and deployed version in the dev namespace."



## When Not to Use Copilot

- Designing complex algorithms from scratch.
- Security-critical code (auth, crypto) unless reviewed by a security expert.
- Large architectural changes without a human-led design discussion.
- Generating full infrastructure setups without manual validation.



## Follow-ups and Improvements

If you find repository-specific preferences (formatters, linters, CI commands, test scripts), update this file to include the exact commands and examples so future Copilot prompts are more accurate.

---
Last updated: 2025-11-05 (fully covers all project requirements)

---
Last updated: 2025-11-05
