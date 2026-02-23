# 1. PROVIDER CONFIGURATION
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}

provider "kubernetes" {
  config_path = "./k3s_config.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "./k3s_config.yaml"
  }
}

# 2. INSTALL ARGO CD + AUTOMATIC PASSWORD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.52.1"
  namespace        = "argocd"
  create_namespace = true

  # Automates the admin password login
  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.argocd_admin_password)
  }

  # Configures the NodePort for external access
  set {
    name  = "server.service.type"
    value = "NodePort"
  }
  set {
    name  = "server.service.nodePorts.https"
    value = "30443"
  }
}

# 3. AUTOMATIC GITHUB REPOSITORY CONNECTION
resource "kubernetes_secret" "github_repo_creds" {
  metadata {
    name      = "yaki-repo-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = "https://github.com/yzimm/yaki-devops-lab"
    password = var.github_token
    username = "git"
  }

  depends_on = [helm_release.argocd]
}

# 4. AUTOMATIC APPLICATION (GITOPS CONFIGURATION)
resource "kubernetes_manifest" "argocd_application" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "yaki-app"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://github.com/yzimm/yaki-devops-lab"
        "targetRevision" = "HEAD"
        "path"           = "."  # FIXED: Now points to root where deployment.yaml lives
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "default"
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }

  depends_on = [kubernetes_secret.github_repo_creds]
}