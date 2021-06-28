resource "aws_db_subnet_group" "private" {
  subnet_ids = module.vpc.private_subnets
  name       = "${var.app_name}-db-subnet-group"
}

resource "aws_db_instance" "database" {
  allocated_storage = 5
  name              = var.app_name
  identifier        = var.db_identifier
  engine            = "postgres"
  instance_class    = "db.t2.micro"
  port              = 5432
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  skip_final_snapshot = true
  tags = {
    "app" = var.app_name
  }
}
