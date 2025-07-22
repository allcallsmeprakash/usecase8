resource "aws_ecr_repository" "appointment_repo" {
  name = var.ecr_appointment_repo
}

resource "aws_ecr_repository" "patient_repo" {
  name = var.ecr_patient_repo
}
