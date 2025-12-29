# AWS
variable "aws_region" {
  default = "eu-central-1"
}

variable "cluster_name" {
  default = "cnd-prod-eks"
  type    = string
}

/*
# ArgoCD
variable "argo_repo_url" {
  default = "https://github.com/CloudNativeDevelopmentTeamH/infra-k8s.git"
  type    = string
}

variable "argo_repo_revision" {
  default = "main"
  type    = string
}

variable "argo_root_path" {
  description = "app-of-apps folder"
  type        = string
}

variable "argo_chart_version" {
  description = "ArgoCD Helm Chart Version"
  default     = ""
  type        = string
}

variable "argo_image_updater_chart_version" {
  description = "ArgoCD Image Updater Helm Chart Version"
  default = ""
  type        = string
}

variable "install_image_updater" {
  default = true
  type    = bool
} */