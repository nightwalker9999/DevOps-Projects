resource "aws_s3_bucket" "this" {
  bucket = var.name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}

# Block public access (defense-in-depth)
resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.enable_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default SSE-S3 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_sse ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Simple lifecycle: transition then expire
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "transition-and-expire"
    status = "Enabled"

    filter {} # all objects

    transition {
      days          = var.lifecycle_transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}
