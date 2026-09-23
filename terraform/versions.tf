terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }

    time = {
      source = "hashicorp/time"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "awscc" {
  region = var.aws_region
}
