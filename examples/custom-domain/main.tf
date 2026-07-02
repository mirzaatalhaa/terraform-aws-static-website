provider "aws" {
  region = "ap-south-1"
}

module "website" {
  source = "mirzaatalhaa/static-website/aws"

  bucket_name  = "my-custom-domain-site"
  project_name = "Custom Domain Example"

  aliases = [
    "example.com",
    "www.example.com"
  ]

  # ACM certificate must be issued in us-east-1 for CloudFront.
  certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}