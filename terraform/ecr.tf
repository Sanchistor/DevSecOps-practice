resource "aws_ecr_repository" "aws-ecr" {
  name = var.app_name
  tags = {
    Environment = var.tag-name
  }
  force_delete = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.aws-ecr.repository_url
}
