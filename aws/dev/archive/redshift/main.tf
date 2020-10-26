terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "redshift/terraform.tfstate"
  }
}

provider "aws" {
    region = "us-east-1"
}

provider "credstash" {
    table  = "dev-credential-store"
    region = "us-east-1"
}

data "credstash_secret" "redshift_master_pass" {
    name = "redshift_master_pass"
}

data "terraform_remote_state" "vpc" {
 backend     = "s3"

 config {
   bucket = "my-terraform-dev"
   key    = "vpc/terraform.tfstate"
   region = "${var.aws_region}"
 }
}

module "redshift" {
  source = "../../modules/data/redshift"

  env                 = "${var.env}"
  redshift_master_password = "${data.credstash_secret.redshift_master_pass.value}"
  subnets = ["${data.terraform_remote_state.vpc.data_subnets}"]
  security_group = ["${data.terraform_remote_state.vpc.data_sg}"]
  number_of_nodes = "${var.number_of_nodes}"
}

