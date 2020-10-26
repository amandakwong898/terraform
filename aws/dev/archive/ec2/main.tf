terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "ec2/terraform.tfstate"
  }
}

locals {
aws_region = "us-east-1"
count = 1
env = "dev"
key_name = "Custom"
server_instance_type = "t3.micro"
instance_count = 4
http_port = 80
ssh_port = 22
}

provider "aws" {
  region = "${local.aws_region}"
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

data "aws_subnet_ids" "app" {
  vpc_id = "${data.aws_vpc.this.id}"
  tags = {
    Name = "app-subnet*-${local.env}"
  }
}

data "aws_subnet_ids" "web" {
  vpc_id = "${data.aws_vpc.this.id}"
  tags = {
    Name = "web-subnet*-${local.env}"
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

module "ec2" {
  source = "../../../modules/compute/ec2"
  count = "${local.count}"
  key_name = "${local.key_name}"
  env = "${local.env}"
  image_id       = "${data.aws_ami.this.id}"
  instance_type = "${local.server_instance_type}"
  subnets = "${data.aws_subnet_ids.app.ids}"
  security_group = ["${data.aws_security_groups.app.ids}"]
}

module "elb" {
  source = "../../../modules/compute/elb"
  name = "elb-${local.env}"
  subnets         = ["${data.aws_subnet_ids.web.ids}"]
  security_groups = ["${data.aws_security_groups.web.ids}"]
  internal        = false
  listener = [
    {
      instance_port     = "${local.http_port}"
      instance_protocol = "HTTP"
      lb_port           = "${local.http_port}"
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = "${local.ssh_port}"
      instance_protocol = "TCP"
      lb_port           = "${local.ssh_port}"
      lb_protocol       = "TCP"
    },
  ]
  health_check = [
    {
      target              = "HTTP:${local.http_port}/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}

module "elb_attach" {
  source = "../../../modules/compute/elb_attachment"
  count = "${local.count}"
  elb = "${module.elb.this_elb_id}"
  instance = "${module.ec2.instances}"
}
