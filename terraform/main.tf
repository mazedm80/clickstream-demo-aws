# Root Terraform script for clickstream demo
terraform {
    required_version = ">= 1.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
}

module "s3_bucket" {
    source = "./modules/s3_bucket"
    env = var.env
}