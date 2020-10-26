terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "jenkins/terraform.tfstate"
  }
}

locals {
aws_region = "us-east-1"
env = "dev"
hostname = "jenkins"
key_name = "Custom"
server_instance_type = "t3.micro"
}

provider "aws" {
  region = local.aws_region
}

provider "random" {
}

data "aws_ami" "this" {
  owners      = ["900892206871"]
  most_recent = true
  filter {
    name   = "name"
    values = ["centos7-pci-dss-*"]
  }
}

module "ec2-jenkins" {
  source = "../../modules/ec2-jenkins"
  env = local.env
  hostname = local.hostname
  image_id = data.aws_ami.this.id
  instance_type = local.server_instance_type
  ssh_key_name = local.key_name
}
