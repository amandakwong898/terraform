data "aws_vpc" "this" {
  tags = {
    Name = "vpc-${var.env}"
  }
}

data "aws_subnet" "this" {
  vpc_id = data.aws_vpc.this.id
  tags = {
    Name = "${var.tier}-subnet-${var.env}-1"
  }
}

data "aws_security_group" "bastion" {
  tags = {
    Name = "bastion-${var.env}"
  }
}

data "aws_security_group" "cicd-lb" {
  tags = {
    Name = "cicd-lb-${var.env}"
  }
}

data "template_file" "this" {
  template = "${file("${path.module}/userdata.tpl")}"
}

resource "aws_instance" "this" {
  instance_type = var.instance_type
  ami = var.image_id
  tags = {
    Name = "${var.hostname}-${var.env}"
    Env = var.env
  }
  key_name = var.ssh_key_name
  vpc_security_group_ids = [data.aws_security_group.bastion.id, data.aws_security_group.cicd-lb.id]
  subnet_id = data.aws_subnet.this.id
  user_data = data.template_file.this.rendered
}
