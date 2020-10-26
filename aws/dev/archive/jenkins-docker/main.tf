terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "jenkins-docker/terraform.tfstate"
  }
}

locals {
aws_region = "us-east-1"
num = 1
env = "dev"
key_name = "Custom"
server_instance_type = "t3.micro"
instance_count = 4
http_port = 80
jenkins_port = 8080
ssh_port = 22
}

provider "aws" {
  region = local.aws_region
}

provider "random" {
}

data "aws_ami" "this" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_vpc" "this" {
  filter {
    name = "tag:Env"
    values = ["${local.env}"]
  }
}

data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_subnet_ids" "app" {
  vpc_id = "${data.aws_vpc.this.id}"
  filter {
    name   = "tag:Name"
    values = ["app-subnet*-${local.env}"]
  }
}

data "aws_subnet_ids" "web" {
  vpc_id = "${data.aws_vpc.this.id}"
  filter {
    name   = "tag:Name"
    values = ["web-subnet*-${local.env}"]
  }
}

data "aws_security_groups" "app" {
  tags = {
    Name = "app-sg-${local.env}"
  }
}

data "aws_security_groups" "web" {
  tags = {
    Name = "web-sg-${local.env}"
  }
}
module "jenkins-docker" {
  source = "../../modules/compute/jenkins-docker"
  num = "${local.num}"
  key_name = "${local.key_name}"
  env = "${local.env}"
  image_id       = "${data.aws_ami.this.id}"
  instance_type = "${local.server_instance_type}"
  subnet_ids = ["data.aws_subnet_ids.app.ids"]
  security_groups = ["data.aws_security_groups.app.ids"]
  vpc_id = "${data.aws_vpc.this.id}"
}

module "elb" {
  source = "../../modules/compute/elb"
  azs = data.aws_availability_zones.this.zone_ids
  env = "${local.env}"
  http_port = local.http_port
  internal = false
  jenkins_port = local.jenkins_port
  name = "elb-${local.env}"
  ssh_port = local.ssh_port
}

module "elb_attach" {
  source = "../../modules/compute/elb_attachment"
  num = "${local.num}"
  elb = "${module.elb.this_elb_id}"
  instance = "${module.jenkins-docker.instances}"
}
