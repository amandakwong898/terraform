variable "accessip" {}

variable "app_cidrs" {
  type = list
}

variable "data_cidrs" {
  type = list
}

variable "env" {}

variable "vpc_cidr" {}

variable "web_cidrs" {
  type = list  
}
