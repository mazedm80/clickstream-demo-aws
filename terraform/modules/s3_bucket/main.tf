# 
resource "aws_s3_bucket" "name" {
    bucket = "click-events-${var.env}-bucket-${random_id.suffix.hex}"
    tags = {
        name = "Click-events bucket"
        environment = var.env
    }
    force_destroy = true
}

resource "random_id" "suffix" {
    byte_length = 4
}

variable "env" {
    description = "Deployment environment"
    type = string
}