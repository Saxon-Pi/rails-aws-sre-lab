resource "aws_db_subnet_group" "main" {
  name = "rails-aws-sre-lab-db-subnet-group"

  # RDS を配置してよい Subnet候補
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name = "rails-aws-sre-lab-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "rails-aws-sre-lab-db"

  engine         = "postgres"
  engine_version = "18"

  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "app_production"
  username = "app"

  # パスワードを RDS側に Secrets Manager で管理させる
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  skip_final_snapshot     = true

  tags = {
    Name = "rails-aws-sre-lab-db"
  }
}
