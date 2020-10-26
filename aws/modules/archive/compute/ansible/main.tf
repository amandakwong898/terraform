data "template_file" "this" {
  count = 4
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    app_subnets = "${element(var.app_subnet_ips, count.index)}"
  }
}

data "aws_iam_role" "this" {
  name = "EC2-admin"
}

resource "aws_iam_instance_profile" "this" {
  name = "ansible_profile"
  role = "${data.aws_iam_role.this.name}"
}

resource "aws_instance" "this" {
  count = "${var.count}"
  iam_instance_profile = "${aws_iam_instance_profile.this.name}"
  instance_type = "${var.instance_type}"
  ami = "${var.image_id}"
  tags {
    Name = "ansible-${var.env}"
    Env = "${var.env}"
  }
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${var.security_group}"]
  subnet_id = "${element(var.subnets, count.index)}"
  user_data = "${data.template_file.this.*.rendered[count.index]}"
}
