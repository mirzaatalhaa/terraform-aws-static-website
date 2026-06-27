provider "aws" {
  region = "ap-south-1"
}

module "website" {
  source = "../.."

  bucket_name  = "my-react-site-demo"
  project_name = "React Demo"
}