variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "environment" {
  description = "The Environment we are using"
  type = string
}
variable "pub_sub_count" {
  description = "Number of public subnets"
  type        = number
}

variable "priv_sub_count" {
  description = "Number of private subnets"
  type        = number
}

#variable "nat_count" {
#  description = "Number of NAT gateways"
#  type        = number
#}

variable "patient_repo_uri" {
    description = "The Patient image repo URL"
    type = string
}
variable "appointment_repo_uri" {
description = "The appointment image repo URL"
type = string
}
