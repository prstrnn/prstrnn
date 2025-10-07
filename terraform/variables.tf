variable "aws_region" {
  description = "AWS region for S3/Route53"
  type        = string
  default     = "eu-west-1"
}


variable "domain_name" {
  description = "Domain managed by Cloudflare Registrar"
  type        = string
  default     = "prstrnn.cc"
}


variable "subdomain" {
  description = "Subdomain to host on S3/CloudFront and delegate to Route 53"
  type        = string
  default     = "cv"
}


variable "project" {
  description = "A short name to make resource names unique."
  type        = string
  default     = "static-site"
}