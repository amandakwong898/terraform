terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "ansible/terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
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

data "terraform_remote_state" "vpc" {
 backend     = "s3"

 config {
   bucket = "my-terraform-dev"
   key    = "vpc/terraform.tfstate"
   region = "${var.aws_region}"
 }
}

module "ansible" {
  source = "../../modules/compute/ansible"
  count = "${var.count}"
  key_name = "${var.key_name}"
  env = "${var.env}"
  image_id       = "${data.aws_ami.this.id}"
  instance_type = "${var.server_instance_type}"
  subnets = "${data.terraform_remote_state.vpc.app_subnets}"
  security_group = ["${data.terraform_remote_state.vpc.app_sg}"]
  app_subnet_ips = "${data.terraform_remote_state.vpc.app_subnet_ips}"
}

module "elb" {
  source = "../../modules/compute/elb"
  name = "elb-${var.env}"
  subnets         = ["${data.terraform_remote_state.vpc.web_subnets}"]
  security_groups = ["${data.terraform_remote_state.vpc.web_sg}"]
  internal        = false
  listener = [
    {
      instance_port     = "${var.ssh_port}"
      instance_protocol = "TCP"
      lb_port           = "${var.ssh_port}"
      lb_protocol       = "TCP"
    },
  ]
  health_check = [
    {
      target              = "TCP:${var.ssh_port}"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}

module "elb_attach" {
  source = "../../modules/compute/elb_attachment"
  count = "${var.count}"
  elb = "${module.elb.this_elb_id}"
  instance = "${module.ansible.instances}"
}
