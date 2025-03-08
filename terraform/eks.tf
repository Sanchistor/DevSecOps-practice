module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  cluster_security_group_id = aws_security_group.eks_control_plane_sg.id

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      vpc_security_group_ids = [aws_security_group.eks_worker_node_sg.id]

      # Attach IAM Role to Worker Nodes
      iam_role_arn = aws_iam_role.worker_node_role.arn
    }
  }
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}