output "instances" {
  value = "${aws_instance.this.*.id}"
}
