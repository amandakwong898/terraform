terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "redis/terraform.tfstate"
  }
}

provider "aws" {
    region = "us-east-1"
}

provider "credstash" {
    table  = "dev-credential-store"
    region = "us-east-1"
}

data "credstash_secret" "cache_token" {
    name = "cache_token"
}

data "terraform_remote_state" "vpc" {
 backend     = "s3"

 config {
   bucket = "my-terraform-dev"
   key    = "vpc/terraform.tfstate"
   region = "${var.aws_region}"
 }
}

module "elasticache-redis" {
  source = "../../modules/data/elasticache-redis"
  env                 = "${var.env}"
  node_type = "cache.t2.micro"
  auth_token = "${data.credstash_secret.cache_token.value}"
  subnets = ["${data.terraform_remote_state.vpc.data_subnets}"]
  security_group = ["${data.terraform_remote_state.vpc.data_sg}"]
  node_type = "cache.t2.micro"
}
