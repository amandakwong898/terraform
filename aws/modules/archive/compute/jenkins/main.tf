data "template_file" "this" {
  num = 1
  template = "${file("${path.module}/userdata.tpl")}"

 vars {
    num = "${count.index}"
  }
}

resource "aws_security_group" "this" {
  name        = "allow_jenkins"
  description = "Allow jenkins traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  count = "${var.num}"
  instance_type = "${var.instance_type}"
  ami = "${var.image_id}"
  tags {
    Name = "jenkins-server-${var.env}-${count.index +1}"
    Env = "${var.env}"
  }
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${var.security_groups}", "${aws_security_group.this.id}"]
  subnet_id = "${element(var.subnet_ids, count.index)}"
  user_data = "${data.template_file.this.*.rendered[count.index]}"
}
