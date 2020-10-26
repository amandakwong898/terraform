variable "env" {}
variable "rds_master_password" {}
variable "security_group" {
  type = "list"
}
variable "subnets" {
  type = "list"
}
