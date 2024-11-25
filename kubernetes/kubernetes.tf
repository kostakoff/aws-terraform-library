# kreate kube api server
resource "aws_eks_cluster" "lab-k8s" {
  name     = var.name
  role_arn = data.aws_iam_role.eks-sa.arn
  version  = "1.31"

  vpc_config {
    security_group_ids = [ aws_security_group.kube-default.id ]
    subnet_ids = [
      data.aws_subnet.lab-a.id,
      data.aws_subnet.lab-b.id,
      data.aws_subnet.lab-c.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = false
  }
  enabled_cluster_log_types = [ ]
  bootstrap_self_managed_addons = false

  zonal_shift_config {
    enabled = false
  }
  upgrade_policy {
    support_type = "STANDARD"
  }
  kubernetes_network_config {
    service_ipv4_cidr = "172.16.0.0/16"
    ip_family = "ipv4"
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

# install calico cni
module "calico-operator" {
  source = "./modules/calico-operator"
  region = var.region
  aws_eks_cluster_name = aws_eks_cluster.lab-k8s.name
}

# install kube proxy, through aws add-on
resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.lab-k8s.name
  addon_name   = "kube-proxy"
  addon_version = "v1.31.2-eksbuild.3"
}

# install kube dns, through aws add-on
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.lab-dev-k8s.name
  addon_name   = "coredns"
  addon_version = "v1.11.3-eksbuild.1"
}

# create master node group
resource "aws_eks_node_group" "master" {
  cluster_name    = aws_eks_cluster.lab-k8s.name
  node_group_name = "${var.name}s-default"
  node_role_arn   = data.aws_iam_role.eks-done-sa.arn
  subnet_ids      = [data.aws_subnet.lab-a.id ]
  
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  instance_types = ["c5.xlarge"]
  disk_size = "30"

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  
  remote_access {
    ec2_ssh_key = "main-key" 
  }
}
