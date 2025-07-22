output "my_vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}

output "internet_gateway_id" {
  value = module.vpc.internet_gateway_id
}

# output "alb_dns_name" {
#   value = module.ec2.alb_dns_name
# }
output "alb_end_point_anme" {
  description = "The DNS name of the Load Balancer"
  value       = module.alb.alb_end_point_anme
}
