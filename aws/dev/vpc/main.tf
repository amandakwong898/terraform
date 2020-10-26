terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "vpc/terraform.tfstate"
  }
}

locals {
  aws_region = "us-east-1"
  env        = "dev"
  vpc_cidr   = "10.10.0.0/16"
  web_cidrs = [
    "10.10.1.0/24",
    "10.10.2.0/24",
    "10.10.3.0/24",
    "10.10.4.0/24",
  ]
  app_cidrs = [
    "10.10.10.0/24",
    "10.10.11.0/24",
    "10.10.12.0/24",
    "10.10.13.0/24",
  ]
  data_cidrs = [
    "10.10.20.0/24",
    "10.10.21.0/24",
    "10.10.22.0/24",
    "10.10.23.0/24",
  ]
  accessip = "0.0.0.0/0"
}

provider "aws" {
  region = local.aws_region
}

module "vpc" {
  source     = "../../modules/vpc"
  vpc_cidr   = local.vpc_cidr
  web_cidrs  = local.web_cidrs
  app_cidrs  = local.app_cidrs
  data_cidrs = local.data_cidrs
  env        = local.env
  accessip   = local.accessip
}

