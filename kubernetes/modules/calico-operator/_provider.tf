terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "kubectl" {
  host                   = var.aws_eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.aws_eks_cluster_certificate_authority)
  token                  = var.aws_eks_cluster_auth_token
  load_config_file       = false
}
