# Static CV Website on cv.prstrnn.cc with Terraform

This Terraform project sets up DNS in **Route 53** for a static website hosted at  
**`cv.prstrnn.cc`**, fronted by **CloudFront**, and secured with an **ACM certificate**.

---

## What it does

- Looks up the parent hosted zone (`prstrnn.cc`) in Route 53.
- Requests an **ACM certificate** for `cv.prstrnn.cc` in **us-east-1** (required for CloudFront).
- Publishes the ACM **DNS validation records** in the parent zone.
- Validates the certificate automatically.
- Creates **A** and **AAAA alias records** in Route 53 for `cv.prstrnn.cc` pointing to the CloudFront distribution.

---

## Simple Graph on how this aligned

```mermaid
flowchart TD
    aws_s3_bucket_cv["s3_bucket\ncv"]
    class aws_s3_bucket_cv awsResource
    aws_s3_bucket_public_access_block_cv["s3_bucket_public_access_block\ncv"]
    class aws_s3_bucket_public_access_block_cv awsResource
    aws_s3_object_assets["s3_object\nassets"]
    class aws_s3_object_assets awsResource
    aws_acm_certificate_cert["acm_certificate\ncert"]
    class aws_acm_certificate_cert awsResource
    aws_route53_zone_zone["route53_zone\nzone"]
    class aws_route53_zone_zone awsResource
    aws_acm_certificate_validation_cert["acm_certificate_validation\ncert"]
    class aws_acm_certificate_validation_cert awsResource
    aws_cloudfront_origin_access_control_oac["cloudfront_origin_access_control\noac"]
    class aws_cloudfront_origin_access_control_oac awsResource
    aws_s3_bucket_policy_site["s3_bucket_policy\nsite"]
    class aws_s3_bucket_policy_site awsResource
    aws_route53_record_alias_a["route53_record\nalias_a"]
    class aws_route53_record_alias_a awsResource
    aws_route53_record_alias_aaaa["route53_record\nalias_aaaa"]
    class aws_route53_record_alias_aaaa awsResource
    data_aws_route53_zone_parent[("data.route53_zone\nparent")]
    class data_aws_route53_zone_parent dataResource

    aws_s3_bucket_cv --> aws_s3_bucket_public_access_block_cv
    aws_s3_bucket_cv --> aws_s3_object_assets
    aws_acm_certificate_cert --> aws_acm_certificate_validation_cert
    aws_s3_bucket_cv --> aws_s3_bucket_policy_site
    aws_route53_zone_zone --> aws_route53_record_alias_a
    aws_route53_zone_zone --> aws_route53_record_alias_aaaa

    subgraph STORAGE["Storage"]
        aws_s3_bucket_cv
        aws_s3_bucket_public_access_block_cv
        aws_s3_bucket_policy_site
    end

    subgraph SECURITY["Security"]
        aws_acm_certificate_cert
        aws_acm_certificate_validation_cert
        aws_cloudfront_origin_access_control_oac
    end

    subgraph NETWORKING["Networking"]
        aws_route53_zone_zone
        aws_route53_record_alias_a
        aws_route53_record_alias_aaaa
        data_aws_route53_zone_parent
    end


    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef azure fill:#0072C6,stroke:#003366,stroke-width:2px,color:#fff
    classDef gcp fill:#4285F4,stroke:#0F9D58,stroke-width:2px,color:#fff
    classDef moduleResource fill:#6B7280,stroke:#374151,stroke-width:2px,color:#fff
    classDef dataResource fill:#9CA3AF,stroke:#4B5563,stroke-width:2px,color:#fff
    classDef variable fill:#FCD34D,stroke:#D97706,stroke-width:2px
    classDef output fill:#34D399,stroke:#059669,stroke-width:2px
    classDef terragruntConfig fill:#5C4EE5,stroke:#4338CA,stroke-width:3px,color:#fff,font-weight:bold
    classDef terragruntDep fill:#8B5CF6,stroke:#7C3AED,stroke-width:2px,stroke-dasharray: 5 5,color:#fff
    classDef terragruntInput fill:#EC4899,stroke:#BE185D,stroke-width:2px,color:#fff

```