/*
# Namespaces
resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "kubernetes_namespace" "argoci" {
  count = var.install_image_updater ? 1 : 0
  metadata { name = "argocd-image-updater" }
} */