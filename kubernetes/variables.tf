variable "name" {
  default = "lab-dev-k8s"
}

variable "region" {
  default = "ca-central-1"
}

variable "aws_vpc_id" {
  default = "vpc-011023bbf28e301b3"
}

variable "aws_subnet_a" {
  default = "subnet-090f313471a11f51b"
}
variable "aws_subnet_b" {
  default = "subnet-091f903eee7bdedb0"
}
variable "aws_subnet_c" {
  default = "subnet-0e6c8eef34e99f233"
}

variable "aws_iam_role_k8s_api" {
  default = "eks-sa"
}

variable "aws_iam_role_k8s_node" {
  default = "eksNodeGroup-sa"
}

variable "aws_route53_zone_id" {
  default = "Z03810243UM55J6Q3VDJT"
}

data "aws_vpc" "lab-vpc" {
  id = var.aws_vpc_id
}

data "aws_subnet" "lab-a" {
  id = var.aws_subnet_a
}

data "aws_subnet" "lab-b" {
  id = var.aws_subnet_b
}

data "aws_subnet" "lab-c" {
  id = var.aws_subnet_c
}

data "aws_iam_role" "eks-sa" {
  name = var.aws_iam_role_k8s_api
}

data "aws_iam_role" "eks-node-sa" {
  name = var.aws_iam_role_k8s_node
}
