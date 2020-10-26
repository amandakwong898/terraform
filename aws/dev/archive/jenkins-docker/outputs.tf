output "elb_address" {
  value = "${module.elb.this_elb_dns_name}"
}
