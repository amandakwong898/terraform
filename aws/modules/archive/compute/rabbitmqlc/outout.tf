output "name" {
  description = "The name of the LC"
  value       = "${element(concat(aws_launch_configuration.this.*.name, list("")), 0)}"
}
