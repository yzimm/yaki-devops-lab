# 🚀 Yaki DevOps Lab

A full end-to-end DevOps pipeline project built from scratch on a hybrid Windows/Ubuntu environment.  
It covers every stage of the modern software delivery lifecycle — local development, CI/CD, containerization, Kubernetes, GitOps, and monitoring.

---

## 🏗️ Architecture

```
Developer (Windows)
       │
       ▼
  git push origin dev
       │
       ▼
GitHub Actions
  ├── Build Docker image
  ├── Push to Docker Hub (yaki2026/my-web-app:dev-{SHA})
  └── Update k8s/overlays/dev/kustomization.yaml
       │
       ▼
  Merge: dev → staging → main
       │
       ▼
ArgoCD (Ubuntu VM / k3s)
  └── Auto-sync → Deploy to production
       │
       ▼
  http://10.93.107.240  ✅
```

---

## 🧰 Tech Stack

| Layer              | Technology                   |
|--------------------|------------------------------|
| Source Control     | GitHub                       |
| CI/CD              | GitHub Actions                |
| Containerization   | Docker + Docker Hub           |
| Local Kubernetes   | kind (dev + staging clusters) |
| Production K8s     | k3s (Ubuntu VM)               |
| GitOps             | ArgoCD                        |
| Config Management  | Kustomize                     |
| Ingress            | Traefik (built into k3s)      |
| Monitoring         | Prometheus + Grafana          |

---

## 📁 Project Structure

```
my-web-app/
├── app/
│   ├── Dockerfile                        # Nginx-based container image
│   └── index.html                        # Web application content
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yaml        # dev-{SHA} image tag
│       ├── staging/
│       │   └── kustomization.yaml        # staging-{SHA} image tag
│       └── prod/
│           └── kustomization.yaml        # prod-{SHA} image tag
├── argocd/
│   └── my-web-app.yaml                   # ArgoCD Application manifest
├── .github/
│   └── workflows/
│       └── build-and-push.yml            # CI/CD pipeline
├── health-check.ps1                      # Pre-demo environment health check
└── build-and-deploy.ps1                  # Local build and deploy script
```

---

## 🔄 CI/CD Pipeline

### Branching Strategy

```
dev  →  staging  →  main (prod)
```

| Branch    | Environment          | Docker Image Tag                    |
|-----------|----------------------|-------------------------------------|
| dev       | kind-dev-cluster     | yaki2026/my-web-app:dev-{SHA}       |
| staging   | kind-staging-cluster | yaki2026/my-web-app:staging-{SHA}   |
| main      | k3s (Ubuntu VM)      | yaki2026/my-web-app:prod-{SHA}      |

### Pipeline Steps (GitHub Actions)

1. Checkout code
2. Install Kustomize v5.4.1
3. Login to Docker Hub
4. Set image tag based on branch + commit SHA
5. Build and push Docker image
6. Update kustomization.yaml overlay with new tag
7. Commit and push changes back to the repo

---

## 🤖 GitOps with ArgoCD

ArgoCD watches the main branch and automatically syncs changes to the production k3s cluster.

| Setting     | Value                                    |
|-------------|------------------------------------------|
| Repo        | https://github.com/yzimm/yaki-devops-lab |
| Path        | k8s/overlays/prod                        |
| Branch      | main                                     |
| Namespace   | default                                  |
| Sync Policy | Automated (prune + self-heal enabled)    |

---

## 📊 Monitoring

| Tool          | Role               | Access                        |
|---------------|--------------------|-------------------------------|
| Prometheus    | Metrics collection | Internal cluster service      |
| Grafana       | Dashboards         | http://10.93.107.240:3000     |
| Alertmanager  | Alert routing      | Internal cluster service      |
| Node Exporter | OS-level metrics   | Runs on Ubuntu VM as DaemonSet|

---

## 🖥️ Environment

| Component       | Details                                   |
|-----------------|-------------------------------------------|
| Windows Machine | Local dev, Docker Desktop, kind clusters  |
| Ubuntu VM       | 10.93.107.240 — k3s, ArgoCD, monitoring   |
| Docker Hub      | yaki2026/my-web-app                       |
| GitHub          | https://github.com/yzimm/yaki-devops-lab  |
| Production App  | http://10.93.107.240                      |

---

## ✅ Pre-Demo Health Check

Run this before every demo to verify the full environment:

```powershell
.\health-check.ps1
```

The script checks 10 sections — local tools, kind clusters, pods, Docker images, Docker Hub, Git branches, SSH/Ubuntu VM, ArgoCD sync, monitoring pods, Grafana, and required project files.

Expected result:

```
PASSED : 37
WARNED : 0
FAILED : 0
ALL CHECKS PASSED - You are ready to demo!
```

---

## 🚀 Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/yzimm/yaki-devops-lab.git
cd yaki-devops-lab
git checkout dev
```

### 2. Make a change
```bash
notepad app\index.html
```

### 3. Push to trigger pipeline
```bash
git add .
git commit -m "your change"
git push origin dev
```

### 4. Watch the pipeline
https://github.com/yzimm/yaki-devops-lab/actions

### 5. Promote to production
```bash
git checkout staging
git merge dev
git push origin staging

git checkout main
git merge staging
git push origin main
```

### 6. Verify deployment
Open: http://10.93.107.240

---

## 🔐 Required GitHub Secrets

| Secret            | Description                         |
|-------------------|-------------------------------------|
| DOCKER_USERNAME   | Docker Hub username (yaki2026)      |
| DOCKER_PASSWORD   | Docker Hub password or access token |

---

## 📝 License

MIT License — built for educational and lab purposes.
