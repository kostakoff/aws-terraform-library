variable "region" {
}

variable "aws_eks_cluster_name" {
}

data "aws_eks_cluster" "main" {
  name = var.aws_eks_cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
}

data "kubectl_file_documents" "calico-operator" {
    content = file("${path.module}/files/calico-v3.29.1.yaml")
}
