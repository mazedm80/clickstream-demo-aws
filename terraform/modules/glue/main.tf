resource "aws_glue_catalog_database" "clickevent" {
  name = "clickevent_${var.env}_db"
}

resource "aws_glue_catalog_table" "event_glue" {
  name = "clickevent_${var.env}_table"
  database_name = aws_glue_catalog_database.clickevent.name

  table_type = "EXTERNAL_TABLE"
  parameters = {
    classification = "parquet"
    "projection.enabled" = "true"
    "projection.year.type" = "integer"
    "projection.year.range" = "2020,2023"
    "projection.month.type" = "integer"
    "projection.month.range" = "1,12"
    "projection.day.type" = "integer"
    "projection.day.range" = "1,31"
    "storage.location.template" = "s3://${var.bucket_name}/clickevent/year=$${year}/month=$${month}/day=$${day}/"
  }

  storage_descriptor {
    location      = "s3://${var.bucket_name}/clickevent/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
    
    columns {
      name = "event_time"
      type = "timestamp"
    }
    columns {
      name = "event_type"
      type = "string"
    }
    columns {
      name = "product_id"
      type = "int"
    }
    columns {
      name = "category_id"
      type = "bigint"
    }
    columns {
      name = "category_code"
      type = "string"
    }
    columns {
      name = "brand"
      type = "string"
    }
    columns {
      name = "price"
      type = "float"
    }
    columns {
      name = "user_id"
      type = "bigint"
    }
    columns {
      name = "user_session"
      type = "varchar(10)"
    }
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
}

variable "bucket_name" {
  description = "S3 bucket name used by Firehose"
  type        = string
}

variable "env" {
  description = "Deployment environment"
  type        = string
}

output "db_name" {
  value = aws_glue_catalog_database.clickevent.name
}

output "table_name" {
  value = aws_glue_catalog_table.event_glue.name
}