resource "aws_security_group" "eks_control_plane_sg" {
  name        = "${var.cluster_name}-control-plane"
  description = "Security group for control plane"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  egress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

}

resource "aws_security_group" "eks_worker_node_sg" {

  name        = "${var.cluster_name}-worker-node"
  description = "Security group for control plane"
  vpc_id      = data.aws_vpc.default.id


  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  ingress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  egress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

  egress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["172.19.0.0/24"]
  }

}