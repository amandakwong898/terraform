provider "random" {
}

resource "random_id" "elb" {
  keepers = {
    # Generate a new id each time we switch to a new name
    name = var.name
  }
  byte_length = 2
}
resource "aws_elb" "this" {
  name            = "${var.name}-${random_id.elb.hex}"
  internal        = var.internal
  availability_zones = ["var.azs"]
  listener {
    instance_port     = var.jenkins_port
    instance_protocol = "TCP"
    lb_port           = var.http_port
    lb_protocol       = "TCP"
  }

  listener {
    instance_port      = var.ssh_port
    instance_protocol  = "TCP"
    lb_port            = var.ssh_port
    lb_protocol        = "TCP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:${var.jenkins_port}"
    interval            = 30
  }

  tags = {
    Env = var.env
    Name = var.name
  }

  lifecycle {
    create_before_destroy = true
  }
}
