# Custom Domain Example

This example demonstrates how to deploy a static website using a custom domain with Amazon CloudFront and an existing AWS Certificate Manager (ACM) certificate.

## Prerequisites

- A registered domain name.
- A validated ACM certificate issued in the **us-east-1** region.
- DNS records configured to point your domain to the CloudFront distribution.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Replace the following values before deployment:

- `bucket_name`
- `aliases`
- `certificate_arn` 