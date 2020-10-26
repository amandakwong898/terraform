terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "ec2-cicd/terraform.tfstate"
  }
}

locals {
bucket = "my-terraform-dev"
env = "dev"
hostname = "cicd"
instance_tier = "app"
jenkins_port = "8080"
key_name = "Custom"
nexus_port = "8081"
region = "us-east-1"
server_instance_type = "t3.large"
sonarqube_port = "9000"
}

provider "aws" {
  region = local.region
}

data "aws_ami" "this" {
  owners      = ["900892206871"]
  most_recent = true
  filter {
    name   = "name"
    values = ["centos7-pci-dss-*"]
  }
}

data "terraform_remote_state" "alb_cicd" {
  backend = "s3"
  config = {
    bucket = local.bucket
    dynamodb_table = "terraform-${local.env}"
    key = "alb-cicd/terraform.tfstate"
    region = local.region
    encrypt = "true"
  }
}

module "ec2_cicd" {
  source = "../../modules/ec2_cicd"
  env = local.env
  hostname = local.hostname
  image_id = data.aws_ami.this.id
  instance_type = local.server_instance_type
  ssh_key_name = local.key_name
  tier = local.instance_tier
}

module "jenkins_ec2_attach_tg" {
  source = "../../modules/ec2_attach_tg"
  instance_id = module.ec2_cicd.instance_id
  port = local.jenkins_port
  tg_arn = "${data.terraform_remote_state.alb_cicd.outputs.jenkins_tg_arn}"
}

module "nexus_ec2_attach_tg" {
  source = "../../modules/ec2_attach_tg"
  instance_id = module.ec2_cicd.instance_id
  port = local.nexus_port
  tg_arn = "${data.terraform_remote_state.alb_cicd.outputs.nexus_tg_arn}"
}

module "sonarqube_ec2_attach_tg" {
  source = "../../modules/ec2_attach_tg"
  instance_id = module.ec2_cicd.instance_id
  port = local.sonarqube_port
  tg_arn = "${data.terraform_remote_state.alb_cicd.outputs.sonarqube_tg_arn}"
}
