provider "random" {
}

data "aws_vpc" "this" {
  tags = {
    Name = "vpc-${var.env}"
  }
}

data "aws_subnet_ids" "this" {
  vpc_id = data.aws_vpc.this.id
  tags = {
    Name = "${var.tier}-subnet-${var.env}-*"
  }
}

resource "random_id" "elb" {
  keepers = {
    # Generate a new id each time we switch to a new name
    name = var.lb_name
  }
  byte_length = 2
}

resource "aws_security_group" "this" {
  vpc_id = data.aws_vpc.this.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "this" {
  name = "${var.lb_name}-${random_id.elb.hex}"
  internal = var.internal
  security_groups = [aws_security_group.this.id]
  subnets = data.aws_subnet_ids.this.ids
  listener {
    instance_port = var.jenkins_port
    instance_protocol = "tcp"
    lb_port = var.jenkins_port
    lb_protocol = "tcp"
  }
  listener {
    instance_port = var.nexus_port
    instance_protocol = "tcp"
    lb_port = var.nexus_port
    lb_protocol = "tcp"
  }
  listener {
    instance_port = var.sonarqube_port
    instance_protocol = "tcp"
    lb_port = var.sonarqube_port
    lb_protocol = "tcp"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:${var.jenkins_port}"
    interval = 30
  }
  tags = {
    Env = var.env
    Name = "${var.lb_name}-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
