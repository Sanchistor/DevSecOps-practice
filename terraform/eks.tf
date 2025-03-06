# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "20.29.0"

#   cluster_name    = var.cluster_name
#   cluster_version = "1.31"

#   cluster_endpoint_public_access           = false
#   enable_cluster_creator_admin_permissions = true

#   vpc_id                    = var.vpc_id
#   subnet_ids                = var.subnet_id
#   cluster_security_group_id = aws_security_group.eks_control_plane_sg.id

#   eks_managed_node_group_defaults = {
#     ami_type            = var.ami_type
#     node_role_arn       = var.iam_role_arn
#     node_security_group = aws_security_group.eks_worker_node_sg.id
#   }

#   eks_managed_node_groups = {
#     one = {
#       name = "node-group-1"

#       instance_types = ["t2.small"]
#       ami_id = var.image_id

#       min_size     = 1
#       max_size     = 3
#       desired_size = 2
#     }

#     two = {
#       name = "node-group-2"

#       instance_types = ["t2.small"]
#       ami_id = var.image_id

#       min_size     = 1
#       max_size     = 2
#       desired_size = 1
#     }
#   }
# }