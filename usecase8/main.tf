
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  pub_sub_count  = var.pub_sub_count
  priv_sub_count = var.priv_sub_count
  #nat_count      = var.nat_count
}
module "alb" {
  source = "./modules/alb"
  public_subnet_ids = module.vpc.public_subnet_ids
  environment = var.environment
  vpc_id = module.vpc.vpc_id
}
module "ecs" {
  source = "./modules/ecs"
  private_subnet_ids = module.vpc.private_subnet_ids
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  patient_repo_uri = var.patient_repo_uri
  appointment_repo_uri = var.appointment_repo_uri
  alb_sg_id = module.alb.alb_sg_id
  patient_target_group_arn = module.alb.patient_target_group_arn
  appointment_target_group_arn = module.alb.appointment_target_group_arn
}
