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

data "aws_eks_cluster_auth" "lab-k8s" {
  name = aws_eks_cluster.lab-k8s.name
}

# install calico cni from kubernetes manifests
module "calico-operator" {
  source = "./modules/calico-operator"
  aws_eks_cluster_auth_token = data.aws_eks_cluster_auth.lab-k8s.token
  aws_eks_cluster_certificate_authority = aws_eks_cluster.lab-k8s.certificate_authority[0].data
  aws_eks_cluster_endpoint = aws_eks_cluster.lab-k8s.endpoint
}

# install kube proxy, through aws add-on
resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.lab-k8s.name
  addon_name   = "kube-proxy"
  addon_version = "v1.31.2-eksbuild.3"

  depends_on = [ 
    module.calico-operator 
  ]
}

# create master node group
resource "aws_eks_node_group" "master" {
  cluster_name    = aws_eks_cluster.lab-k8s.name
  node_group_name = "${var.name}-master"
  node_role_arn   = data.aws_iam_role.eks-done-sa.arn
  subnet_ids      = [data.aws_subnet.lab-a.id ]
  
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  instance_types = ["c5.large"]
  disk_size = "30"

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  
  remote_access {
    ec2_ssh_key = "main-key" 
  }

  depends_on = [ 
    aws_eks_addon.kube-proxy
  ]
}

# install kube dns, through aws add-on
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.lab-k8s.name
  addon_name   = "coredns"
  addon_version = "v1.11.3-eksbuild.1"

  depends_on = [ 
    aws_eks_node_group.master 
  ]
}
