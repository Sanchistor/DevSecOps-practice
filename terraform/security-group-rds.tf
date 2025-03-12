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

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }
}
