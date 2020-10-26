data "template_file" "this" {
  count = 4
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    count = "${count.index}"
  }
}

resource "aws_instance" "this" {
  count = "${var.count}"
  instance_type = "${var.instance_type}"
  ami = "${var.image_id}"
  tags {
    Name = "web-server-${var.env}-${count.index +1}"
    Env = "${var.env}"
  }
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${var.security_group}"]
  subnet_id = "${element(var.subnets, count.index)}"
  user_data = "${data.template_file.this.*.rendered[count.index]}"
}
