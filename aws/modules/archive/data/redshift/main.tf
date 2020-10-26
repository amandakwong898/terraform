
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["vpc-${var.env}"]
  }
}

resource "aws_redshift_subnet_group" "this" {
    name = "redshift-subnet-group-${var.env}"
    description = "Our main group of subnets"
    subnet_ids = ["${var.subnets}"]
}


resource "aws_redshift_cluster" "this" {
  cluster_identifier = "redshift-cluster-${var.env}"
  database_name      = "redshift_${var.env}"
  master_username    = "master"
  master_password    = "${var.redshift_master_password}"
  node_type          = "dc2.large"
  number_of_nodes     = "${var.number_of_nodes}"
  vpc_security_group_ids  = ["${var.security_group}"]
  cluster_subnet_group_name  = "${aws_redshift_subnet_group.this.name}"
  skip_final_snapshot = false
}

resource "aws_security_group" "this" {
  name        = "redshift-sg-${var.env}"
  vpc_id      = "${data.aws_vpc.this.id}"

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
