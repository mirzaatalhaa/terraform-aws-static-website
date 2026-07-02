provider "aws" {
  region = "ap-south-1"
}

module "website" {
  source = "mirzaatalhaa/static-website/aws"

  bucket_name  = "my-react-site-demo"
  project_name = "React Demo"
  aliases = [
    "example.com"
  ]
  certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/12345678-1234-1234-1234-123456789012" 
}