variable "env" {}
variable "key_name" {}
variable "image_id" {}

variable "app_subnet_ips" {
  type = "list"
}

variable "count" {}
variable "instance_type" {}
variable "security_group" {
  type = "list"
}
variable "subnets" {
  type = "list"
}
