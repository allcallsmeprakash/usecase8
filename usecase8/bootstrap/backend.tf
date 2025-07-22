terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket = "training-usecases"
    key    = "usecase7/bootstrap/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}
