output "elb_dns_name" {
  value       = "${element(concat(aws_elb.this.*.dns_name, list("")), 0)}"
}

output "elb_id" {
  value       = aws_elb.this.id
}

output "elb_security_group" {
  value = aws_security_group.this.id
}
