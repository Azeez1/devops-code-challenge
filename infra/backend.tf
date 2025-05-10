terraform {
  backend "s3" {
    bucket         = "lightfeather-s3"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lightfeather-locks"
    encrypt        = true
  }
}
