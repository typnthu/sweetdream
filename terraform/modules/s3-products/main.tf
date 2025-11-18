# S3 Bucket for Product Images
resource "aws_s3_bucket" "products" {
  bucket = var.bucket_name

  tags = {
    Name        = "SweetDream Product Images"
    Environment = var.environment
  }
}

# Enable versioning for product images
resource "aws_s3_bucket_versioning" "products" {
  bucket = aws_s3_bucket.products.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "products" {
  bucket = aws_s3_bucket.products.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access configuration for product images
resource "aws_s3_bucket_public_access_block" "products" {
  bucket = aws_s3_bucket.products.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read access to products folder
resource "aws_s3_bucket_policy" "products" {
  bucket = aws_s3_bucket.products.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.products.arn}/products/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.products]
}

# CORS configuration for web access
resource "aws_s3_bucket_cors_configuration" "products" {
  bucket = aws_s3_bucket.products.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Lifecycle policy for product images
resource "aws_s3_bucket_lifecycle_configuration" "products" {
  bucket = aws_s3_bucket.products.id

  rule {
    id     = "optimize-storage"
    status = "Enabled"

    filter {
      prefix = "products/"
    }

    # Move to Intelligent-Tiering after 30 days
    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
