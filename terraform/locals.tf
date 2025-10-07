locals {
  subdomain_fqdn = "${var.subdomain}.${var.domain_name}"
  bucket_name    = "${replace(local.subdomain_fqdn, ".", "-")}-${var.project}"
}

locals {
  site_dir   = "${path.module}/site"
  site_files = fileset(local.site_dir, "**/*")
}