data "kubectl_file_documents" "calico-operator" {
    content = file("${path.module}/files/calico-v3.29.1.yaml")
}

variable "aws_eks_cluster_endpoint" {
}

variable "aws_eks_cluster_certificate_authority" {
}

variable "aws_eks_cluster_auth_token" {
}
