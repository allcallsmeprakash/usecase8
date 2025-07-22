terraform {
  backend "s3" {
    bucket         = "training-usecases"
    key            = "uc8/terraform.tfstate"
    region         = "us-east-1"                
    use_lockfile = true

  }
}
