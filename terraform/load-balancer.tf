//Security group for load balancer for K8S
resource "aws_security_group" "load_balancer_sg" {
  name        = "${var.cluster_name}-load-balancer"
  description = "Security group for load balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere (internet)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere (internet) for HTTPS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}


resource "aws_lb" "myapp_lb" {
  name               = "${var.cluster_name}-load-balancer"
  internal           = false
  load_balancer_type = "application" # Use application load balancer (ALB)
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = data.aws_subnets.default.ids
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.cluster_name}-load-balancer"
  }
}

resource "aws_lb_target_group" "myapp_target_group" {
  name     = "${var.cluster_name}-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.cluster_name}-target-group"
  }
}

resource "aws_lb_listener" "myapp_listener" {
  load_balancer_arn = aws_lb.myapp_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_target_group.arn
  }
}

# //Deploy aws load balancer controller via helm
# resource "helm_release" "aws_lb_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"

#   set {
#     name  = "clusterName"
#     value = data.aws_eks_cluster.cluster.name
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }
# }
