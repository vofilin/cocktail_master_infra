module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.1.0"

  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  enable_nat_gateway = false
  enable_vpn_gateway = false
  enable_dns_support = true
}

module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "${var.app_name}-db-security_group"
  description = "Security group for PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.vpc_cidr_block]
  ingress_rules       = ["postgresql-tcp"]
}

module "ecs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "${var.app_name}-ec-security_group"
  description = "Security group for ECS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  egress_with_cidr_blocks = [{
    from_port   = 0
    to_port     = 0
    protocol    = -1
    description = "Allow all egress traffic"
    cidr_blocks = "0.0.0.0/0"
  }]
}
