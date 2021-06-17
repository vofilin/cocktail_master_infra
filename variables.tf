variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

variable "app_name" {
  description = "Application"
  type        = string
  default     = "cocktail_master"
}

variable "db_identifier" {
  description = "Database identifier."
  type        = string
  default     = "cocktail-master-db"
}


variable "db_username" {
  description = "Database administrator username."
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password."
  type        = string
  default     = "password"
  sensitive   = true
}

variable "django_key" {
  description = "Django secret key"
  type        = string
  default     = "somesecretkey"
  sensitive   = true
}

variable "repo_url" {
  description = "Docker repository url."
  type        = string
  default     = "vfilin/cocktail_master"
}

variable "image_tag" {
  description = "Docker image tag."
  type        = string
  default     = "1.2.2"
}
