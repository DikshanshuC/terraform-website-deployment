terraform {
  backend "s3" {
    bucket         = "terraform-diksha-bb-bucket"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "terraform-diksha-website-bucket"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index_html" {
  bucket        = aws_s3_bucket.website_bucket.bucket
  key           = "index.html"
  source        = "my-static-website/index.html"
  content_type  = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket        = aws_s3_bucket.website_bucket.bucket
  key           = "error.html"
  source        = "my-static-website/error.html"
  content_type  = "text/html"
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website_bucket.bucket}"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.bucket}"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate { cloudfront_default_certificate = true }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}

output "website_url" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
}

output "s3_website_url" {
  value = aws_s3_bucket.website_bucket.bucket_regional_domain_name
}

# Save and run:
# terraform init
# terraform apply

# Let me know if anything breaks or needs tweaking! 🚀

