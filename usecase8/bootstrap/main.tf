resource "aws_ecr_repository" "appointment_repo" {
  name = var.ecr_repo_name
}

resource "aws_ecr_repository" "patient_repo" {
  name = var.ecr_repo_name
}
