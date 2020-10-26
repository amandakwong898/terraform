resource "aws_elb_attachment" "this" {
  elb      = var.elb
  instance = var.instance
  lifecycle {
    create_before_destroy = true
  }
}
