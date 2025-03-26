terraform {
  backend "s3" {
    key     = "ecr/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
