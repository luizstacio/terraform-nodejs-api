resource "aws_s3_bucket" "app" {
  bucket     = var.bucket
  acl        = "private"
  
  versioning {
    enabled = true
  }

  tags       = var.tags
}

resource "aws_ssm_parameter" "bucket_name" {
  name        = "/${var.app}/${var.environment}/bucketName"
  type        = "String"
  value       = var.bucket
  overwrite   = true
  tags        = var.tags
}