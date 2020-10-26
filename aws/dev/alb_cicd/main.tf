terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "alb-cicd/terraform.tfstate"
  }
}

locals {
  accessip = "0.0.0.0/0"
  aws_region = "us-east-1"
  env = "dev"
  domain = "joelkwong.com"
  https_port = "443"
  jenkins_port = "8080"
  nexus_port = "8081"
  region = "us-east-1"
  sonarqube_port = "9000"
  tier = "web"
}

provider "aws" {
  region = local.aws_region
}

module "alb_cicd" {
  source = "../../modules/alb_cicd"
  accessip = local.accessip
  domain = local.domain
  env = local.env
  https_port = local.https_port
  jenkins_port = local.jenkins_port
  nexus_port = local.nexus_port
  sonarqube_port = local.sonarqube_port 
  tier = local.tier 
}
