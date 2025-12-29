variable "enable_argocd" {
  type    = bool
}

# Namespaces
resource "kubernetes_namespace" "argocd" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name = var.argocd_namespace
  }
}

# Deploy ArgoCD via Helm
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name      = "argocd"
  namespace = kubernetes_namespace.argocd[0].metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.18"

  values = [
    yamlencode({
      crds = {
        install = true
      }

      configs = {
        params = {
          "server.insecure" = "true"
        }
      }

      server = {
        ingress = { enabled = false }
      }

      dex            = { enabled = false }
      notifications  = { enabled = false }
      applicationset = { enabled = true }
    })
  ]

  depends_on = [
    aws_eks_access_policy_association.current_user_admin,
  ]
}

# Seed
resource "kubernetes_manifest" "root_app" {
  count = var.enable_argocd ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = var.argocd_namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"

      source = {
        repoURL        = var.argo_repo_url
        targetRevision = var.argo_repo_revision
        path           = var.argo_root_path
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_namespace
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "PruneLast=true",
          "ServerSideApply=true"
        ]
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    aws_eks_access_policy_association.current_user_admin,
  ]
}

# ArgoCD Image Updater
resource "helm_release" "argocd_image_updater" {
  count = var.enable_argocd ? 1 : 0

  name      = "argocd-image-updater"
  namespace = kubernetes_namespace.argocd[0].metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "0.10.2"

  values = [
    yamlencode({
      config = {
        argocd = {
          serverAddress = "argocd-server.${var.argocd_namespace}.svc"
          insecure      = true
        }
      }
      service = { type = "ClusterIP" }
    })
  ]

  depends_on = [
    helm_release.argocd,
    aws_eks_access_policy_association.current_user_admin,
  ]
}