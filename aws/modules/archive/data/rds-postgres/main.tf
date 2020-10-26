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

resource "aws_db_subnet_group" "this" {
    name = "postgres subnet group for ${var.env}"
    description = "Our main group of subnets"
    subnet_ids = ["${var.subnets}"]
}

resource "aws_db_instance" "main" {
  identifier              = "rds-instance-${var.env}"
  allocated_storage       = 10
  storage_type            = "gp2"
  engine                  = "postgres"
  instance_class          = "db.t2.small"
  name                    = "${title(var.env)}RdsPostgresMain"
  username                = "master"
  password                = "${var.rds_master_password}"
  db_subnet_group_name    = "${aws_db_subnet_group.this.name}"
  vpc_security_group_ids  = ["${var.security_group}"]
  backup_retention_period = 7
  skip_final_snapshot	  = true

  tags {
    Name        = "rds-instance-${var.env}-main"
    Env         = "${var.env}"
  }
}

resource "aws_db_instance" "replica" {
  identifier             = "rds-instance-${var.env}-replica"
  replicate_source_db    = "${aws_db_instance.main.identifier}"
  storage_type           = "gp2"
  instance_class         = "db.t2.small"
  name                   = "${title(var.env)}RdsPostgresReplica"
  vpc_security_group_ids = ["${var.security_group}"]
  skip_final_snapshot    = true

  tags {
    Name        = "rds-instance-${var.env}-replica"
    Env         = "${var.env}"
  }
}
