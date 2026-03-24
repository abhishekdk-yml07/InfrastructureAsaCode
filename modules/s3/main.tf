variable "project_name" { type = string }
variable "environment"  { type = string }
data "aws_caller_identity" "current" {}
locals { name = "${var.project_name}-${var.environment}" }

resource "aws_s3_bucket" "app" {
  bucket        = "${local.name}-app-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"
  tags          = { Name = "${local.name}-app" }
}
resource "aws_s3_bucket_versioning"                    "app" { bucket = aws_s3_bucket.app.id; versioning_configuration { status = "Enabled" } }
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" }; bucket_key_enabled = true }
}
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id
  block_public_acls = true; block_public_policy = true; ignore_public_acls = true; restrict_public_buckets = true
}
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = aws_s3_bucket.app.id
  rule {
    id = "tiering"; status = "Enabled"
    transition { days = 30;  storage_class = "STANDARD_IA" }
    transition { days = 90;  storage_class = "GLACIER" }
    noncurrent_version_expiration { noncurrent_days = 90 }
  }
}

output "bucket_name" { value = aws_s3_bucket.app.bucket }
output "bucket_arn"  { value = aws_s3_bucket.app.arn }
