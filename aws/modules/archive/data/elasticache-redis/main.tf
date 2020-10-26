data "aws_subnet_ids" "this" {
  # Gets all the subnets in this security group
  vpc_id = "${data.aws_vpc.this.id}"
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["vpc-${var.env}"]
  }
}

provider "random" {}

resource "random_id" "random" {
  byte_length = 2
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "redis-subnet-${var.env}-${random_id.random.hex}"
  subnet_ids = ["${var.subnets}"]
}

data "credstash_secret" "cache_token" {
    name    = "cache_token"
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "redis-cache-${var.env}-${random_id.random.hex}"
  replication_group_description = "Shared Redis Group in ${var.env}"
  engine                        = "redis"
  engine_version                = "4.0.10"
  node_type                     = "${var.node_type}"
  number_cache_clusters         = "${var.number_of_clusters}"
  security_group_ids            = ["${var.security_group}"]
  subnet_group_name 		= "${aws_elasticache_subnet_group.this.name}"
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  auth_token			= "${var.auth_token}"
}
