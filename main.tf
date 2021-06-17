terraform {
  backend "s3" {
    bucket = "terraform-cocktail-master"
    region = "eu-central-1"
    key    = "state.tfstate"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}
