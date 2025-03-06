resource "aws_db_instance" "rds" {
  engine                 = "postgres"
  engine_version         = "16.3"
  db_name                = var.database_name
  identifier             = "${var.database_name}-id"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  publicly_accessible    = true
  username               = var.db-username
  password               = var.db-password
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = {
    Enviroment = var.tag-name
  }
}