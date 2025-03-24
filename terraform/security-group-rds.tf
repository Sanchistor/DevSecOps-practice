data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "rds" {
  vpc_id = data.aws_vpc.default.id
  name   = "rds-sg"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["212.142.114.55/32"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }
}
