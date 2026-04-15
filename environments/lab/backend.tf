terraform {
  backend "s3" {
    bucket  = "servicestack-tfstate"
    key     = "environments/lab/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
