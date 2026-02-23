# 🚀 K3s GitOps & IaC Lab

A professional-grade implementation of **GitOps** principles using **Terraform** to provision a **K3s** cluster management layer and **Argo CD** to handle automated application deployments.



## 🏗️ The Architecture
* **Infrastructure-as-Code:** Terraform manages Helm releases and Kubernetes manifests.
* **Cluster:** K3s (lightweight Kubernetes) running on an Ubuntu VM.
* **GitOps Controller:** Argo CD monitoring this repository for state changes.
* **Network:** External access configured via NodePort and secure Port-Forwarding.

## 🛠️ Tech Stack
* **Terraform** (v1.x+)
* **Kubernetes** (K3s)
* **Argo CD**
* **Helm**
* **Ubuntu Linux**

## ⚙️ Setup & Deployment
1. **Prepare Secrets:** Create a `terraform.tfvars` file (see `variables.tf.example`).
2. **Initialize & Apply:**
   ```bash
   terraform init
   terraform apply -auto-approve
