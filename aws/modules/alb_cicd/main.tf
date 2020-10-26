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

data "aws_route53_zone" "this" {
  name         = "${var.domain}."
}

resource "aws_security_group" "this" {
  vpc_id = data.aws_vpc.this.id
  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "TCP"
    cidr_blocks = [var.accessip]
  }
  ingress {
    from_port   = var.jenkins_port
    to_port     = var.jenkins_port
    protocol    = "TCP"
    cidr_blocks = [var.accessip]
  }
  ingress {
    from_port   = var.nexus_port
    to_port     = var.nexus_port
    protocol    = "TCP"
    cidr_blocks = [var.accessip]
  }
  ingress {
    from_port   = var.sonarqube_port
    to_port     = var.sonarqube_port
    protocol    = "TCP"
    cidr_blocks = [var.accessip]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = [var.accessip]
  }
  tags = {
    Env = var.env
    Name = "cicd-lb-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
}

resource "aws_lb" "cicd" {
  name = "cicd-lb-${var.env}-${substr(uuid(),0,3)}"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.this.id]
  subnets = data.aws_subnet_ids.this.ids
  enable_deletion_protection = false
  tags = {
    Env = var.env
    Name = "cicd-lb-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
}

resource "aws_lb_target_group" "jenkins_tg" {
  name = "jenkins-tg-${var.env}-${substr(uuid(),0,3)}"
  port = var.jenkins_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.this.id
  tags = {
    Env = var.env
    Name = "cicd-lb-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "jenkins_listener" {
  load_balancer_arn = aws_lb.cicd.arn
  port = var.jenkins_port
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
    type = "forward"
  }
}

resource "aws_lb_target_group" "nexus_tg" {
  name = "nexus-tg-${var.env}-${substr(uuid(),0,3)}"
  port = var.nexus_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.this.id
  tags = {
    Env = var.env
    Name = "cicd-lb-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "nexus_listener" {
  load_balancer_arn = aws_lb.cicd.arn
  port = var.nexus_port
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.nexus_tg.arn
    type = "forward"
  }
}

resource "aws_lb_target_group" "sonarqube_tg" {
  name = "sonarqube-tg-${var.env}-${substr(uuid(),0,3)}"
  port = var.sonarqube_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.this.id
  tags = {
    Env = var.env
    Name = "cicd-lb-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "sonarqube_listener" {
  load_balancer_arn = aws_lb.cicd.arn
  port = var.sonarqube_port
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.sonarqube_tg.arn
    type = "forward"
  }
}

resource "aws_route53_record" "cicd" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "cicd"
  type    = "CNAME"
  ttl     = "5"
  records = [aws_lb.cicd.dns_name]
}
