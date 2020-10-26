variable "auth_token" {}

variable "env" {}

variable "node_type" {}

variable "number_of_clusters" {
  default = 1
}

variable "security_group" { type = "list" }

variable "subnets" { type = "list" }
