provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_s3_bucket" "cv" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "cv" {
  bucket                  = aws_s3_bucket.cv.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "assets" {
  for_each = { for f in local.site_files : f => f if !endswith(f, "/") }

  bucket = aws_s3_bucket.cv.id
  key    = each.value
  source = "${local.site_dir}/${each.value}"
  etag   = filemd5("${local.site_dir}/${each.value}")
  content_type = lookup({ # with AI
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
  }, split(".", each.value)[length(split(".", each.value)) - 1], null)

}

# SSL sertificate to enable HTTPS
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = local.subdomain_fqdn
  validation_method = "DNS"
}

data "aws_route53_zone" "parent" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_zone" "zone" {
  name = local.subdomain_fqdn
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]

}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# Cloudfront setup

# Access to s3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-oac"
  description                       = "OAC for ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.subdomain_fqdn
  aliases             = [local.subdomain_fqdn]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    compress = true

  }

  origin {
    domain_name              = aws_s3_bucket.cv.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid     = "AllowCloudFrontOAC"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.cv.arn}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.cv.id
  policy = data.aws_iam_policy_document.bucket.json
}

# DNS
# A/AAAA alias records in the delegated Route 53 zone
resource "aws_route53_record" "alias_a" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = local.subdomain_fqdn
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "alias_aaaa" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = local.subdomain_fqdn
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}