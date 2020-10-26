data "template_file" "this" {
  count = 4
  template = "${file("${path.module}/userdata.tpl")}"
}

resource "aws_launch_configuration" "this" {
  name_prefix = "lc-${var.env}-"
  instance_type = "${var.instance_type}"
  image_id = "${var.image_id}"
  key_name = "${var.key_name}"
  security_groups = ["${var.security_groups}"]
  user_data = "${data.template_file.this.*.rendered[count.index]}"
  lifecycle {
    create_before_destroy = true
  }
}
