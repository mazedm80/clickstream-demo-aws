resource "aws_kinesis_firehose_delivery_stream" "clickevent" {
    name = "click-events-${var.env}-delivery"
    destination = "extended_s3"

    extended_s3_configuration {
    role_arn = var.role_arn
    bucket_arn = var.bucket_arn
    buffering_size = 64
    buffering_interval = 60

    processing_configuration {
      enabled = true
      processors {
        type = "MetadataExtraction"

        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{event_type: .event_type, yy: .event_time[0:4], mm: .event_time[5:7], dd: .event_time[8:10]}"
        }

        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
    dynamic_partitioning_configuration {
      enabled = "true"
    }

    prefix = "clickevent/year=!{partitionKeyFromQuery:yy}/month=!{partitionKeyFromQuery:mm}/day=!{partitionKeyFromQuery:dd}/event_type=!{partitionKeyFromQuery:event_type}/"
    error_output_prefix = "error/clickevent/"
    
    compression_format = "UNCOMPRESSED"    

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            convert_dots_in_json_keys_to_underscores = true
            case_insensitive = true
          }
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        role_arn      = var.role_arn
        catalog_id    = data.aws_caller_identity.current.account_id
        database_name = var.db_name
        table_name    = var.table_name
        region        = var.aws_region
      }
    }
  }
}

variable "env" {
    description = "Deployment environment"
    type = string
}

variable "aws_region" {
    description = "AWS region."
    type = string
}

variable "bucket_arn" {
    description = "S3 bucket ARN for Firehose delivery stream."
    type = string
}

variable "role_arn" {
    description = "IAM role ARN for Firehose delivery stream."
    type = string
}

variable "db_name" {
    description = "Glue database name for Firehose delivery stream."
    type = string
}

variable "table_name" {
    description = "Glue table name for Firehose delivery stream."
    type = string
}

data "aws_caller_identity" "current" {
  # This data source retrieves the AWS account ID of the current user
}

output "stream_name" {
  value = aws_kinesis_firehose_delivery_stream.clickevent.name
}