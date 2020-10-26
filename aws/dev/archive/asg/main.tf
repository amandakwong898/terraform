terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "asg/terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "my-terraform-dev"
    key    = "vpc/terraform.tfstate"
    region = "${var.aws_region}"
  }
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

module "lc" {
  env		 = "${var.env}"
  key_name	 = "${var.key_name}"
  source         = "../../modules/compute/lc"
  instance_type  = "${var.server_instance_type}"
  security_groups = ["${data.terraform_remote_state.vpc.app_sg}"]
  image_id       = "${data.aws_ami.this.id}"
}

resource "aws_security_group" "this" {
  name_prefix   = "asg-sg-${var.env}-"

  ingress {
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "asg" {
  source               = "../../modules/compute/asg"
  name                 = "asg-${var.env}"
  launch_configuration = "${module.lc.name}"
  vpc_zone_identifier  = ["${data.terraform_remote_state.vpc.app_subnets}"]
  env                  = "${var.env}"
  app                  = "${var.app}"
  load_balancers       = ["${module.elb.this_elb_name}"]
}

module "elb" {
  source          = "../../modules/compute/elb"
  name            = "asg-elb-${var.env}"
  subnets         = ["${data.terraform_remote_state.vpc.web_subnets}"]
  security_groups = ["${data.terraform_remote_state.vpc.web_sg}"]
  internal        = false

  listener = [
    {
      instance_port     = "${var.http_port}"
      instance_protocol = "HTTP"
      lb_port           = "${var.http_port}"
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = "${var.ssh_port}"
      instance_protocol = "TCP"
      lb_port           = "${var.ssh_port}"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:${var.http_port}/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}
