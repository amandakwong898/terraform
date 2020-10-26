output "database_name" {
  value = "${aws_db_instance.main.name}"
}

output "hosted_zone_id" {
  value = "${aws_db_instance.main.hosted_zone_id}"
}

output "endpoint" {
  value = "${aws_db_instance.main.endpoint}"
}

output "address" {
  value = "${aws_db_instance.main.address}"
}
