terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "bastion/terraform.tfstate"
  }
}

locals {
aws_region = "us-east-1"
env = "dev"
hostname = "bastion"
key_name = "Custom"
server_instance_type = "t3.micro"
tier = "web"
}

provider "aws" {
  region = local.aws_region
}

data "aws_ami" "this" {
  owners      = ["900892206871"]
  most_recent = true
  filter {
    name   = "name"
    values = ["centos7-pci-dss-*"]
  }
}

module "ec2_bastion" {
  source = "../../modules/ec2_bastion"
  env = local.env
  hostname = local.hostname
  image_id = data.aws_ami.this.id
  instance_type = local.server_instance_type
  ssh_key_name = local.key_name
  tier = local.tier
}
