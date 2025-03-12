resource "aws_security_group" "eks_control_plane_sg" {
  name        = "${var.cluster_name}-control-plane"
  description = "Security group for control plane"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  egress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

}

resource "aws_security_group" "eks_worker_node_sg" {
  name        = "${var.cluster_name}-worker-node"
  description = "Security group for worker node"
  vpc_id      = data.aws_vpc.default.id

  # Allow traffic from Internet
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress: Allow communication between worker nodes and Kubernetes components (ports 10250, 10256)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  ingress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  egress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  egress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id] # Reference to RDS security group
  }

  # Egress: Allow traffic to Kubernetes API server and necessary external services like S3 or ECR registry
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
