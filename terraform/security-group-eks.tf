resource "aws_security_group" "eks_control_plane_sg" {
  name        = "${var.cluster_name}-control-plane"
  description = "Security group for the EKS control plane"
  vpc_id      = data.aws_vpc.default.id

  # Allow inbound traffic from worker nodes to API server (port 6443)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_worker_node_sg.id]
  }

  # Allow outbound traffic to worker nodes
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "eks_worker_node_sg" {
  name        = "${var.cluster_name}-worker-node"
  description = "Security group for worker nodes"
  vpc_id      = data.aws_vpc.default.id

  # Allow worker nodes to receive communication from the control plane (port 10250)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_control_plane_sg.id]
  }

  # ✅ Allow nodes to communicate with each other using `self`
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

