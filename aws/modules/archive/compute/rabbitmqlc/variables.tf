variable "env" {}
variable "image_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "security_groups" {
  type = "list"
}
variable "aws_region" {}
variable "rabbitmq_secret_cookie" {}
variable "rabbitmq_admin_password" {}
