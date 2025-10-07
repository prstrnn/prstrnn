output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "CloudFront domain (useful for testing before DNS)."
}


output "route53_delegation_nameservers" {
  value       = aws_route53_zone.zone.name_servers
  description = "Add these as NS records for the subdomain label in Cloudflare (e.g., 'site' NS -> these 4 names)."
}


output "website_url" {
  value       = "https://${local.subdomain_fqdn}"
  description = "Your site URL."
}


output "uploaded_keys" {
  value = keys(aws_s3_object.assets)
}


output "moduledir" {
  value = local.site_dir
}
