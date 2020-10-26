terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "rabbitmq/terraform.tfstate"
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

provider "credstash" {
    table  = "dev-credential-store"
    region = "us-east-1"
}

data "credstash_secret" "rabbitmq_admin_password" {
    name = "rabbitmq_admin_password"
}

data "credstash_secret" "rabbitmq_secret_cookie" {
    name = "rabbitmq_secret_cookie"
}

module "lc" {
  source         = "../../modules/compute/rabbitmqlc"
  aws_region	 = "${var.aws_region}"
  env		 = "${var.env}"
  key_name	 = "${var.key_name}"
  instance_type  = "${var.server_instance_type}"
  security_groups = ["${data.terraform_remote_state.vpc.app_sg}","${aws_security_group.lc.id}"]
  image_id       = "${data.aws_ami.this.id}"
  rabbitmq_admin_password = "${data.credstash_secret.rabbitmq_admin_password.value}"
  rabbitmq_secret_cookie = "${data.credstash_secret.rabbitmq_secret_cookie.value}"
}

resource "aws_security_group" "lc" {
  name_prefix   = "rabbitmq-lc-sg-${var.env}-"
  vpc_id	= "${data.terraform_remote_state.vpc.vpc_id}"
 
  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    from_port   = "${var.rabbitmq_port}"
    to_port     = "${var.rabbitmq_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.rabbitmqconsole_port}"
    to_port     = "${var.rabbitmqconsole_port}"
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

resource "aws_security_group" "elb" {
  name_prefix   = "rabbitmq-elb-sg-${var.env}-"
  vpc_id	= "${data.terraform_remote_state.vpc.vpc_id}"
 
  ingress {
    from_port   = "${var.rabbitmqconsole_port}"
    to_port     = "${var.rabbitmqconsole_port}"
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
  name                 = "rabbitmq-asg-${var.env}"
  app                  = "${var.app}"
  launch_configuration = "${module.lc.name}"
  vpc_zone_identifier  = ["${data.terraform_remote_state.vpc.app_subnets}"]
  env                  = "${var.env}"
  load_balancers       = ["${module.elb.this_elb_name}"]
}

module "elb" {
  source          = "../../modules/compute/elb"
  name            = "rabbitmq-asg-elb-${var.env}"
  subnets         = ["${data.terraform_remote_state.vpc.web_subnets}"]
  security_groups = ["${data.terraform_remote_state.vpc.web_sg}","${aws_security_group.elb.id}"]
  internal        = false

  listener = [
    {
      instance_port     = "${var.rabbitmqconsole_port}"
      instance_protocol = "TCP"
      lb_port           = "${var.http_port}"
      lb_protocol       = "TCP"
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
      target              = "TCP:${var.ssh_port}"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}
