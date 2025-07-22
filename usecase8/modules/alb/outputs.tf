output "alb_sg_id" {
    value = aws_security_group.alb.id
}
output "patient_target_group_arn" {
value  = aws_lb_target_group.patient_service.arn
}
output "appointment_target_group_arn" {
    value = aws_lb_target_group.appointment_service.arn
}
output "alb_end_point_anme" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.main.dns_name
}
