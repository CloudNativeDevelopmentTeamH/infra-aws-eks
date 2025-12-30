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
}

# Wait for ArgoCD CRDs to be available
resource "null_resource" "wait_for_argocd_crds" {
  count = var.enable_argocd ? 1 : 0

  triggers = {
    helm_release_version = var.enable_argocd ? helm_release.argocd[0].version : ""
    helm_release_chart   = var.enable_argocd ? helm_release.argocd[0].chart : ""
  }

  provisioner "local-exec" {
    command = <<-EOT
      until kubectl get crd applications.argoproj.io 2>/dev/null; do
        echo "Waiting for ArgoCD CRDs to be registered..."
        sleep 5
      done
      echo "ArgoCD CRDs are now available"
    EOT
  }

  depends_on = [
    helm_release.argocd
  ]
}

# Seed - Deploy root Application via kubectl
resource "null_resource" "root_app" {
  count = var.enable_argocd ? 1 : 0

  triggers = {
    repo_url      = var.argo_repo_url
    repo_revision = var.argo_repo_revision
    root_path     = var.argo_root_path
    namespace     = var.argocd_namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: root
        namespace: ${self.triggers.namespace}
        finalizers:
        - resources-finalizer.argocd.argoproj.io
      spec:
        project: default
        source:
          repoURL: ${self.triggers.repo_url}
          targetRevision: ${self.triggers.repo_revision}
          path: ${self.triggers.root_path}
        destination:
          server: https://kubernetes.default.svc
          namespace: ${self.triggers.namespace}
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
          - CreateNamespace=true
          - PruneLast=true
          - ServerSideApply=true
      EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete application root -n ${self.triggers.namespace} --ignore-not-found=true"
  }

  depends_on = [
    null_resource.wait_for_argocd_crds
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
    helm_release.argocd
  ]
}