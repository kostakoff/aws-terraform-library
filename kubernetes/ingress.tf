# create ingress node group
resource "aws_eks_node_group" "ingress" {
  cluster_name    = aws_eks_cluster.lab-k8s.name
  node_group_name = "${var.name}-ingress"
  node_role_arn   = data.aws_iam_role.eks-node-sa.arn
  subnet_ids      = [data.aws_subnet.lab-a.id ]
  
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  instance_types = ["t3.medium"]
  disk_size = "30"

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  
  labels = {
    "role" = "ingress"
  }
  
  taint {
    key = "node-role.kubernetes.io/ingress"
    effect = "NO_SCHEDULE"
  }

  remote_access {
    ec2_ssh_key = "main-key"
  }

  depends_on = [ 
    aws_eks_addon.coredns
  ]
}

module "ingress-operator" {
  source = "./modules/ingress-operator"
  aws_eks_cluster_auth_token = data.aws_eks_cluster_auth.lab-k8s.token
  aws_eks_cluster_certificate_authority = aws_eks_cluster.lab-k8s.certificate_authority[0].data
  aws_eks_cluster_endpoint = aws_eks_cluster.lab-k8s.endpoint
}

resource "aws_security_group_rule" "ingress-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_node_group.ingress.resources[0].remote_access_security_group_id
}

data "aws_autoscaling_group" "ingress-nodes" {
  name = aws_eks_node_group.ingress.resources[0].autoscaling_groups[0].name
}

resource "aws_lb_target_group" "ingress" {
  name     = "${var.name}-ingress"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.aws_vpc_id
}

resource "aws_lb" "ingress" {
  name               = "${var.name}-ingress"
  load_balancer_type = "network"
  internal = true
  ip_address_type = "ipv4"
  security_groups = [aws_security_group.kube-default.id]
  subnets = [ data.aws_subnet.lab-a.id ]

/*  subnet_mapping {
    subnet_id = data.aws_subnet.lab-a.id
    private_ipv4_address = "10.10.112.23"
  }*/
}

resource "aws_lb_listener" "ingress" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

resource "aws_autoscaling_attachment" "ingress" {
  autoscaling_group_name = data.aws_autoscaling_group.ingress-nodes.name
  lb_target_group_arn    = aws_lb_target_group.ingress.arn
}

resource "aws_route53_record" "ingess" {
  zone_id = var.aws_route53_zone_id
  name    = "*.${var.name}.myltd.lab"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.ingress.dns_name]
}
