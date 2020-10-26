variable "env" {}
variable "key_name" {}
variable "image_id" {}

variable "num" {}
variable "instance_type" {}
variable "security_groups" {
  type = "list"
}
variable "subnet_ids" {
  type = "list"
}
variable "vpc_id" {}
