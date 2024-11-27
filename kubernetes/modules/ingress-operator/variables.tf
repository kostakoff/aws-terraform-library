data "kubectl_path_documents" "docs" {
    pattern = "${path.module}/files/*.yaml"
}

variable "aws_eks_cluster_endpoint" {
}

variable "aws_eks_cluster_certificate_authority" {
}

variable "aws_eks_cluster_auth_token" {
}
