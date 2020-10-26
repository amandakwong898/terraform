variable "env" {}
variable "key_name" {}
variable "image_id" {}
variable "instance_type" {}
variable "num" {}
variable "security_groups" {
  type = list
}
variable "subnet_ids" {
  type = list
}
variable "vpc_id" {}
