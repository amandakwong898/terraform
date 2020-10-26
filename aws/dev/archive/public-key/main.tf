terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "my-terraform-dev"
    region         = "us-east-1"
    dynamodb_table = "terraform-dev"
    key            = "public-key/terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

provider "credstash" {
    table  = "dev-credential-store"
    region = "us-east-1"
}

data "credstash_secret" "dev_key" {
    name = "dev_key"
}

module "public-key" {
  source = "../../modules/iam/public-key"
  key_name = "${var.key_name}"
  public_key = "${data.credstash_secret.dev_key.value}"
}
