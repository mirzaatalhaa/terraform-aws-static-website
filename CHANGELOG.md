# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

---

## [1.0.0] - 2026-06-28

### Added

- Initial release of the Terraform AWS React Static Website module.
- Provisioning of a private Amazon S3 bucket for hosting static website assets.
- Amazon CloudFront distribution for secure global content delivery.
- Origin Access Control (OAC) integration for secure access to the S3 bucket.
- Automatic S3 Bucket Policy generation using Terraform IAM policy documents.
- HTTPS enforcement through CloudFront's default SSL certificate.
- Support for React Single Page Applications (SPA) using custom CloudFront error responses.
- Optimized CloudFront cache behavior using AWS managed cache policies.
- IPv6 support.
- Configurable resource tagging.
- Input variables for bucket name, project name, IPv6, default root object, and tags.
- Useful module outputs including CloudFront domain name, distribution ID, bucket name, and bucket ARN.
- Example configuration under `examples/basic`.
- Comprehensive README documentation.
- MIT License.