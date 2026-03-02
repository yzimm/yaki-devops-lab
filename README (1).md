# Yaki DevOps Lab — Full CI/CD Pipeline Project

## Overview

This project demonstrates a complete DevOps pipeline built from scratch, including local Kubernetes clusters, automated CI/CD with GitHub Actions, Docker Hub image registry, GitOps deployment with Argo CD, and production monitoring with Prometheus, Grafana, and Alertmanager.

---

## Architecture

```
Developer (Windows)
        │
        ▼
Local Kind Clusters (dev + staging)
        │
        ▼
Git Push → GitHub (dev / staging / main branches)
        │
        ▼
GitHub Actions CI Pipeline
        │
        ▼
Docker Hub (yaki2026/my-web-app)
        │
        ▼
Argo CD (Ubuntu VM) → Auto Deploy
        │
        ├── Dev Environment
        ├── Staging Environment
        └── Prod Environment
                │
                ▼
        Prometheus + Grafana + Alertmanager
```

---

## Project Structure

```
my-web-app/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI pipeline
├── app/
│   ├── Dockerfile              # Docker build definition
│   └── index.html              # Application source
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml     # Base Kubernetes deployment
│   │   ├── service.yaml        # Kubernetes service
│   │   └── kustomization.yaml  # Base kustomize config
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yaml   # Dev overrides (image tag: dev)
│       ├── staging/
│       │   └── kustomization.yaml   # Staging overrides (image tag: staging)
│       └── prod/
│           └── kustomization.yaml   # Prod overrides (image tag: latest)
└── build-and-deploy.ps1        # Local automation script
```

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Docker Desktop | Local container runtime |
| kind (Kubernetes in Docker) | Local Kubernetes clusters |
| Kustomize | Environment-specific K8s configs |
| GitHub Actions | CI pipeline — build & push images |
| Docker Hub | Container image registry |
| Argo CD | GitOps continuous deployment |
| Prometheus | Metrics collection |
| Grafana | Metrics visualization & dashboards |
| Alertmanager | Alerting & notifications |
| Helm | Kubernetes package manager |
| Terraform | Infrastructure as Code |

---

## Branch Strategy

| Branch | Environment | Docker Tag | Deployed By |
|---|---|---|---|
| `dev` | Dev | `:dev` | Argo CD |
| `staging` | Staging | `:staging` | Argo CD |
| `main` | Production | `:latest` | Argo CD |

---

## CI/CD Pipeline Flow

### 1. Developer pushes code
```bash
git push origin dev        # triggers dev build
git push origin staging    # triggers staging build
git push origin main       # triggers prod build
```

### 2. GitHub Actions (`.github/workflows/ci.yml`)
- Checks out code
- Logs into Docker Hub using secrets
- Builds Docker image from `./app`
- Tags image based on branch (`dev` / `staging` / `latest`)
- Pushes image to Docker Hub (`yaki2026/my-web-app:<tag>`)

### 3. Argo CD (Ubuntu VM — 10.93.107.240)
- Watches GitHub repo for changes
- Automatically syncs kustomize overlays
- Deploys updated pods to the correct environment

---

## Local Development

### Prerequisites
- Docker Desktop
- kind
- kubectl
- PowerShell

### Build and Deploy Locally

```powershell
# Deploy to dev only
.\build-and-deploy.ps1 -env dev

# Deploy to staging only
.\build-and-deploy.ps1 -env staging

# Deploy to both dev and staging
.\build-and-deploy.ps1 -env both
```

The script automatically:
1. Builds the Docker image
2. Pushes to Docker Hub
3. Loads image into the kind cluster
4. Applies kustomize overlay
5. Restarts the deployment
6. Waits for rollout to complete

---

## Kubernetes Clusters

### Local (Windows — kind)
| Cluster | Environment |
|---|---|
| `dev-cluster` | Development |
| `staging-cluster` | Staging |

### Remote (Ubuntu VM)
| Cluster | Environment |
|---|---|
| k3s (default) | Production + Monitoring |

---

## Argo CD

Argo CD is installed on the Ubuntu VM and manages all deployments automatically.

### Access Argo CD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open: `https://localhost:8080`

### Applications
| App Name | Branch | Path | Namespace |
|---|---|---|---|
| `my-web-app-dev` | `dev` | `k8s/overlays/dev` | `default` |
| `my-web-app-staging` | `staging` | `k8s/overlays/staging` | `default` |
| `my-web-app-prod` | `main` | `k8s/overlays/prod` | `default` |

---

## Monitoring Stack

Installed via Helm on the Ubuntu VM using `kube-prometheus-stack`.

### Components
| Component | Purpose |
|---|---|
| Prometheus | Scrapes and stores metrics |
| Grafana | Dashboards and visualization |
| Alertmanager | Manages and routes alerts |
| Node Exporter | Host-level metrics |
| kube-state-metrics | Kubernetes object metrics |

### Access Grafana
```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring --address 0.0.0.0 &
```
Then open: `http://10.93.107.240:3000`

- **Username:** `admin`
- **Password:** `admin123`

### Key Dashboards
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Pod
- Node Exporter / Full

---

## GitHub Secrets Required

| Secret | Value |
|---|---|
| `DOCKER_USERNAME` | `yaki2026` |
| `DOCKER_PASSWORD` | Docker Hub access token |

---

## Docker Hub

Images are stored at: `https://hub.docker.com/r/yaki2026/my-web-app`

| Tag | Branch | Environment |
|---|---|---|
| `latest` | `main` | Production |
| `staging` | `staging` | Staging |
| `dev` | `dev` | Development |

---

## Author

**yzimm** — [github.com/yzimm/yaki-devops-lab](https://github.com/yzimm/yaki-devops-lab)
