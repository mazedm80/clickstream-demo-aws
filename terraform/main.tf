# Root Terraform script for clickstream demo
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_bucket" {
  source = "./modules/s3_bucket"
  env    = var.env
}

module "iam_roles" {
  source      = "./modules/aws_iam_role"
  env         = var.env
  bucket_name = module.s3_bucket.bucket_name
}

module "firehose" {
  source     = "./modules/firehose"
  env        = var.env
  aws_region = var.aws_region
  bucket_arn = module.s3_bucket.bucket_arn
  role_arn   = module.iam_roles.firehose_role_arn
  db_name    = module.glue.db_name
  table_name = module.glue.table_name
}

module "glue" {
  source = "./modules/glue"
  env    = var.env
  bucket_name = module.s3_bucket.bucket_name
}