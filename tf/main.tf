terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27.0"
    }
  }
  backend "s3" {
    bucket = "*****************"
    key    = "sample"
  }
}