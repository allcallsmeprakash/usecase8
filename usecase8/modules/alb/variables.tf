variable "public_subnet_ids" {
description = "The public subnet id"
type = list(string)
}
variable "environment" {
  description = "The Environment we are using"
  type = string
}
variable "vpc_id" {
    description = "The VPC ID"
    type = string
}
