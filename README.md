# Terraform AWS Static Website Module

> A Terraform module that deploys a secure, production-ready static website on AWS using Amazon S3 and Amazon CloudFront — compatible with any framework that produces a static build output.

<div align="center">

[![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-7B42BC?logo=terraform)](https://registry.terraform.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.5.0-blue)](https://www.terraform.io/downloads)

</div>

---

## Overview

Managing cloud infrastructure by hand — clicking through the AWS Console, applying ad-hoc changes, and hoping nothing drifts — is a recipe for inconsistency and outages. This module takes a different approach.

**`terraform-aws-static-website`** encapsulates the full infrastructure required to host any static website on AWS into a self-contained, reusable Terraform module. Whether you are deploying a React SPA, a Vue app, an Angular build, a Next.js static export, or a plain HTML site, the infrastructure requirements are identical: a private S3 bucket, a CloudFront distribution, and the glue between them. Instead of copying and pasting that configuration across projects, you declare this module once and let Terraform handle the rest.

The module was designed with three goals in mind:

- **Reusability** — Any Terraform configuration can consume this module with a few lines of HCL. No copy-pasting resources between projects.
- **Security by default** — The S3 bucket is private. CloudFront is the only permitted origin. HTTPS is enforced at the distribution level. Public access is blocked at the bucket level.
- **Production readiness** — IPv6 support, response compression, optimized caching, and client-side routing support are enabled out of the box.

This module follows [Terraform Registry best practices](https://developer.hashicorp.com/terraform/registry/modules/publish) and is structured to be published as a public or private registry module.

---

## Features

| Feature | Description |
|---|---|
| 🪣 **Private S3 Bucket** | All website assets are stored in a private bucket with no public access |
| 🌐 **CloudFront Distribution** | Global CDN with edge caching and low-latency delivery |
| 🔐 **Origin Access Control (OAC)** | Modern AWS-recommended method for restricting S3 access to CloudFront only |
| 🔒 **HTTPS by Default** | HTTP requests are redirected to HTTPS at the CloudFront level |
| ↩️ **SPA / Client-Side Routing Support** | Custom error responses remap S3 404/403 errors to `index.html` so the browser router takes over |
| 🧩 **Framework Agnostic** | Works with any framework that emits a static build: React, Vue, Angular, Svelte, Next.js (static export), Astro, Vite, plain HTML, and more |
| ⚡ **Optimized Caching** | CloudFront caching behaviours are tuned for static asset delivery |
| 📦 **Automatic Compression** | Gzip and Brotli compression enabled for supported content types |
| 🌍 **IPv6 Support** | Configurable dual-stack support for IPv4 and IPv6 traffic |
| 🛡️ **Secure Bucket Policy** | IAM policy restricts `s3:GetObject` to the CloudFront service principal only |
| 🚫 **Public Access Block** | All four S3 public access block settings are enabled |
| 🔧 **Configurable Variables** | Key parameters are exposed as input variables with sensible defaults |
| 📤 **Useful Outputs** | CloudFront domain, distribution ID, bucket name, and ARN are all exported |
| 🏷️ **Resource Tagging** | All resources accept a `tags` map for cost allocation and resource management |
| 🧩 **Modular Architecture** | Single-responsibility design; extend or compose with other modules |
| ✅ **Production-Ready Defaults** | Secure, performant defaults that work without configuration |

---

## Architecture

```
                          ┌─────────────────────────────────┐
                          │            Internet             │
                          └────────────────┬────────────────┘
                                           │ HTTPS
                                           ▼
                          ┌─────────────────────────────────┐
                          │     Amazon CloudFront           │
                          │    (Global CDN / Edge Layer)    │
                          │                                 │
                          │  • TLS termination              │
                          │  • HTTP → HTTPS redirect        │
                          │  • Edge caching                 │
                          │  • Gzip / Brotli compression    │
                          │  • IPv6 support                 │
                          │  • SPA error remapping          │
                          └────────────────┬────────────────┘
                                           │ OAC-signed request
                                           ▼
                          ┌─────────────────────────────────┐
                          │   Origin Access Control (OAC)   │
                          │                                 │
                          │  • Signs requests with SigV4    │
                          │  • Restricts S3 to CF only      │
                          └────────────────┬────────────────┘
                                           │ Authenticated
                                           ▼
                          ┌─────────────────────────────────┐
                          │      Private Amazon S3          │
                          │   (No public access allowed)    │
                          │                                 │
                          │  • index.html                   │
                          │  • assets/js/main.*.js          │
                          │  • assets/css/main.*.css        │
                          │  • images/*, fonts/*, etc.      │
                          └─────────────────────────────────┘
```

### Component breakdown

**Amazon CloudFront** sits at the edge of the network between the user's browser and the S3 bucket. It serves cached copies of your static assets from AWS edge locations around the world, reducing latency for end users regardless of their geographic location. Placing CloudFront in front of S3 also allows you to enforce HTTPS, apply caching policies, and remap error responses — none of which S3 static website hosting can do securely.

**Origin Access Control (OAC)** is the mechanism that ties CloudFront to S3. When CloudFront forwards a request to S3, it signs the request using AWS Signature Version 4 and presents credentials that identify itself as the CloudFront service principal. The S3 bucket policy is written to allow `s3:GetObject` only when the request arrives with this signature. OAC replaces the older Origin Access Identity (OAI) mechanism and is now the AWS-recommended approach.

**The private S3 bucket** stores the compiled static build output of your application — typically whatever your framework writes to a `build/`, `dist/`, `out/`, or `public/` directory. Because OAC handles authentication at the CloudFront layer, the bucket itself has no static website hosting enabled and no public access. It is impossible to access bucket objects directly via the S3 URL — all traffic must pass through CloudFront.

---

## How It Works

### Step-by-step deployment flow

**1. Terraform provisions the S3 bucket**

An `aws_s3_bucket` resource is created using the `bucket_name` variable. The bucket name must be globally unique across all AWS accounts.

**2. Public access is blocked**

An `aws_s3_bucket_public_access_block` resource is attached to the bucket with all four block settings set to `true`: `block_public_acls`, `ignore_public_acls`, `block_public_policy`, and `restrict_public_buckets`. This prevents any misconfigured policy from accidentally exposing the bucket contents.

**3. CloudFront Origin Access Control is created**

An `aws_cloudfront_origin_access_control` resource is created. This control references the S3 origin domain and configures SigV4 request signing with `always` signing behaviour — meaning every request from CloudFront to S3 is signed, regardless of whether the object is cached.

**4. CloudFront Distribution is configured**

An `aws_cloudfront_distribution` resource is provisioned with the following key settings:

- `default_root_object` set to `index.html`
- `viewer_protocol_policy` set to `redirect-to-https`
- Compress set to `true` for automatic Gzip/Brotli
- `ipv6_enabled` controlled by the `enable_ipv6` variable
- `PriceClass_100` (North America and Europe) as the default price class

**5. CloudFront is connected to S3**

The distribution's origin block references the S3 bucket's regional domain name (not the website endpoint) and attaches the OAC ID. This tells CloudFront exactly which S3 bucket to use and how to authenticate with it.

**6. The IAM bucket policy is generated dynamically**

Terraform's `aws_iam_policy_document` data source generates a policy that allows `s3:GetObject` only when the `aws:SourceArn` condition matches the CloudFront distribution ARN. This is the policy that enforces the "CloudFront only" access pattern.

**7. HTTPS is enforced**

The CloudFront viewer protocol policy is set to `redirect-to-https`, meaning any HTTP request is automatically upgraded to HTTPS. There is no way to access the site over plain HTTP.

**8. SPA routing is configured**

Two custom error responses are attached to the distribution. When S3 returns a `403 Forbidden` or `404 Not Found` (which happens on any direct route request like `/about`), CloudFront remaps the response to `index.html` with a `200 OK` status. React Router then reads the URL and renders the correct component client-side.

**9. Outputs are returned**

After `terraform apply` completes, the module outputs the CloudFront domain name, distribution ID, S3 bucket name, and bucket ARN. These can be consumed by the root module or by CI/CD pipelines for deployment and cache invalidation.

---

## Security

### Why the S3 bucket is private

Hosting a static site directly via S3 static website hosting exposes the bucket to the public internet without TLS, without a CDN, and without any way to enforce access controls. This module deliberately disables S3 static website hosting and blocks all public access. The bucket is only accessible via the CloudFront distribution.

### Why OAC is preferred over OAI

Origin Access Identity (OAI) is a legacy mechanism. It uses a special CloudFront user identity that must be granted access via an S3 bucket ACL or bucket policy. OAI does not support AWS Signature Version 4, which means it cannot be used with certain S3 features including SSE-KMS encryption with customer-managed keys.

Origin Access Control (OAC) was introduced in 2022 and resolves these limitations. It uses SigV4 to sign every request from CloudFront to S3, supports SSE-KMS, and ties access to the specific CloudFront distribution ARN rather than a shared identity — making it more auditable and more secure.

### How the bucket policy restricts access

The generated IAM policy uses a condition key to enforce access:

```json
{
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::<account_id>:distribution/<distribution_id>"
    }
  }
}
```

This means even if an attacker obtained the S3 bucket name and attempted to access objects directly or from a different CloudFront distribution, the request would be denied.

### Principle of Least Privilege

The bucket policy grants only the minimum permission required: `s3:GetObject` on the bucket's objects. No `s3:ListBucket`, no `s3:PutObject`, no `s3:DeleteObject`. CloudFront reads objects; it does not need any other capability.

### HTTPS enforcement

The `viewer_protocol_policy` is set to `redirect-to-https` on the default cache behaviour. This ensures that even if a user or link targets `http://`, the browser is immediately redirected to the HTTPS version. There is no path to accessing the site without TLS.

---

## Client-Side Routing Support

### Supported frameworks

This module is compatible with any tool that compiles to static files. The infrastructure is identical regardless of the framework — what differs is only your build command and the directory you sync to S3.

| Framework | Build command | Output directory |
|---|---|---|
| React (Create React App) | `npm run build` | `build/` |
| React (Vite) | `npm run build` | `dist/` |
| Vue (Vite / Vue CLI) | `npm run build` | `dist/` |
| Angular | `ng build` | `dist/<project>/` |
| Svelte / SvelteKit (static) | `npm run build` | `build/` |
| Next.js (static export) | `next build` | `out/` |
| Astro (static) | `astro build` | `dist/` |
| Nuxt (static) | `nuxt generate` | `.output/public/` |
| Docusaurus | `npm run build` | `build/` |
| Hugo | `hugo` | `public/` |
| MkDocs | `mkdocs build` | `site/` |
| Jekyll | `bundle exec jekyll build` | `_site/` |
| Plain HTML/CSS/JS | — | your source directory |

### Why client-side routed apps break on page refresh

Frameworks that use client-side routing (React Router, Vue Router, Angular Router, SvelteKit, etc.) work by loading a single `index.html` and then handling all navigation in the browser using the History API. No full page loads occur when the user clicks between routes.

This works correctly when the user lands on the root URL (`/`). The problem arises when the user:

- Directly navigates to a deep URL like `https://example.com/dashboard/settings`
- Refreshes the browser on any route other than `/`
- Shares or bookmarks a link to an internal route

When this happens, the browser sends a request to CloudFront for `/dashboard/settings`. CloudFront forwards it to S3, looking for an object at that exact key path. No such object exists — only `index.html` and your compiled assets are in the bucket. S3 returns a `403 Forbidden` (the key doesn't exist in a private bucket) or a `404 Not Found`. Without correction, the user sees an error page.

> **Note:** Frameworks that generate a static HTML file per route at build time — such as Astro, Hugo, Jekyll, MkDocs, Docusaurus, and Next.js with full static export — are not affected by this problem, since the file `/dashboard/settings/index.html` actually exists in S3. The error remapping below is still harmless for these frameworks.

### How this module solves the problem

The module attaches two custom error response rules to the CloudFront distribution:

```
S3 returns 403  →  CloudFront serves /index.html  →  Response code: 200
S3 returns 404  →  CloudFront serves /index.html  →  Response code: 200
```

When CloudFront intercepts a `403` or `404` from S3, it substitutes `index.html` and returns a `200 OK` to the browser. The browser loads the application shell. The client-side router reads `window.location.pathname` (which is still `/dashboard/settings`) and renders the correct view. The user never sees an error.

This approach requires no changes to your application code and is transparent to the end user.

---

## Terraform Concepts Used

This module demonstrates the following Terraform patterns and concepts. If you are learning Terraform, this module is a useful reference.

**Modules** — The core concept this project illustrates. A module is a self-contained collection of Terraform resources that accepts input variables and exports outputs. Modules enable you to encapsulate infrastructure patterns and share them across teams and projects.

**Resources** — Declarations of infrastructure objects managed by Terraform. This module uses `aws_s3_bucket`, `aws_cloudfront_distribution`, `aws_s3_bucket_policy`, `aws_cloudfront_origin_access_control`, and `aws_s3_bucket_public_access_block`.

**Data Sources** — Used to generate the IAM policy document via `aws_iam_policy_document`. Data sources read existing data without creating infrastructure; in this case, they produce a JSON IAM policy string that is passed to `aws_s3_bucket_policy`.

**Variables** — Input parameters declared in `variables.tf`. Each variable has a type constraint, a description, and an optional default value. Variables allow the same module to be used across multiple environments with different configurations.

**Outputs** — Values exported from the module via `outputs.tf`. Outputs surface information about the created resources — such as the CloudFront domain name — so the consuming configuration can use them in other resources or display them to the operator.

**Nested Blocks** — Terraform's HCL supports nested configuration blocks within resources. This module uses nested blocks extensively for CloudFront — `origin`, `default_cache_behavior`, `custom_error_response`, `restrictions`, and `viewer_certificate` are all nested blocks within `aws_cloudfront_distribution`.

**Resource References** — Resources can reference attributes of other resources using `<resource_type>.<name>.<attribute>` syntax. For example, the CloudFront distribution references `aws_s3_bucket.website.bucket_regional_domain_name` so that Terraform automatically creates the correct dependency graph and applies resources in the right order.

**IAM Policy Documents** — Rather than embedding JSON strings in your configuration, Terraform's `aws_iam_policy_document` data source lets you write IAM policies in HCL and have Terraform render the JSON. This enables variable interpolation inside policies and produces cleaner, more maintainable code.

**Provider Configuration** — The AWS provider requires a `region` to be set. This module accepts the provider from the root configuration via provider inheritance, following the pattern recommended for child modules.

---

## Requirements

| Name | Version |
|---|---|
| [terraform](https://www.terraform.io/downloads) | >= 1.5.0 |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 5.0.0 |

---

## Providers

| Name | Version |
|---|---|
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 5.0.0 |

---

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `bucket_name` | The name of the S3 bucket to create. Must be globally unique across all AWS accounts. | `string` | n/a | **yes** |
| `project_name` | A short identifier for the project. Used to name the CloudFront OAC and as a prefix for resource descriptions. | `string` | n/a | **yes** |
| `default_root_object` | The object CloudFront returns when the root URL is requested. Should match your React build entry point. | `string` | `"index.html"` | no |
| `enable_ipv6` | Whether to enable IPv6 (dual-stack) on the CloudFront distribution. | `bool` | `true` | no |
| `tags` | A map of tags to apply to all resources created by this module. Useful for cost allocation, environment labelling, and resource grouping. | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|---|---|
| `cloudfront_domain_name` | The domain name assigned to the CloudFront distribution (e.g., `d1a2b3c4e5f6g7.cloudfront.net`). Use this as your website URL or as the target for a CNAME record in your DNS provider. |
| `cloudfront_distribution_id` | The ID of the CloudFront distribution. Required for cache invalidation commands (`aws cloudfront create-invalidation --distribution-id <id> --paths "/*"`). |
| `bucket_name` | The name of the S3 bucket where website assets are stored. Use this in your CI/CD pipeline to sync build artifacts (`aws s3 sync ./dist s3://<bucket_name> --delete`). Substitute `./dist` with your framework's actual output directory. |
| `bucket_arn` | The full ARN of the S3 bucket. Useful when composing this module with others that need to reference the bucket (e.g., an S3 replication or backup module). |

---

## Usage

### Basic example

```hcl
provider "aws" {
  region = "us-east-1"
}

module "website" {
  source = "<registry-placeholder>/terraform-aws-static-website"

  bucket_name  = "my-app-prod-assets"
  project_name = "my-app"

  tags = {
    Environment = "production"
    Project     = "my-app"
    ManagedBy   = "terraform"
  }
}

output "website_url" {
  value = "https://${module.website.cloudfront_domain_name}"
}
```

### With optional variables

```hcl
provider "aws" {
  region = "us-east-1"
}

module "website" {
  source = "<registry-placeholder>/terraform-aws-static-website"

  bucket_name          = "my-app-staging-assets"
  project_name         = "my-app"
  default_root_object  = "index.html"
  enable_ipv6          = false

  tags = {
    Environment = "staging"
    Project     = "my-react-app"
    Owner       = "platform-team"
    CostCenter  = "engineering"
    ManagedBy   = "terraform"
  }
}
```

### Accessing outputs

After running `terraform apply`, retrieve outputs to use in your deployment workflow:

```bash
# Get the website URL
terraform output website_url

# Get the bucket name for syncing build artifacts
# Adjust the local path to match your framework's output directory (build/, dist/, out/, etc.)
BUCKET=$(terraform output -raw bucket_name)
aws s3 sync ./dist s3://$BUCKET --delete

# Get the distribution ID for cache invalidation
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

---

## Examples

The `examples/basic/` directory contains a complete, runnable Terraform configuration that demonstrates how to consume this module from a root configuration.

```
examples/
└── basic/
    ├── main.tf        # Module call with sample variable values
    ├── outputs.tf     # Exposes module outputs at the root level
    └── README.md      # Instructions for running the example
```

To run the example:

```bash
cd examples/basic
terraform init
terraform plan
terraform apply
```

This example provisions a working CloudFront + S3 stack using placeholder values. It is designed to be a starting point, not a production configuration. Review the variable values in `main.tf` before applying to your own AWS account.

---

## Module Structure

```
terraform-aws-static-website/
├── main.tf            # All resource definitions (S3, CloudFront, OAC, bucket policy)
├── variables.tf       # Input variable declarations with types and descriptions
├── outputs.tf         # Output value declarations
├── README.md          # This file — module documentation
├── LICENSE            # MIT License
├── examples/
│   └── basic/
│       ├── main.tf    # Example root module consuming this module
│       ├── outputs.tf # Example outputs
│       └── README.md  # Example-specific usage instructions
└── .gitignore         # Excludes .terraform/, tfstate files, and override files
```

**`main.tf`** contains the core infrastructure: the S3 bucket and its public access block, the CloudFront origin access control, the CloudFront distribution with all its nested configuration blocks, the IAM policy document data source, and the S3 bucket policy resource.

**`variables.tf`** declares every input the module accepts. Each variable includes a `type`, a `description`, and where appropriate a `default`. This file is the interface between the module and its consumers.

**`outputs.tf`** exports key attributes of the created resources. Outputs are how consumers get information back out of a module — such as the CloudFront domain to display or pass to a DNS record.

**`examples/basic/`** is a self-contained Terraform configuration that consumes this module. It exists to demonstrate real-world usage and to make the module testable in CI.

**`.gitignore`** excludes files that should never be committed to source control: the `.terraform/` provider cache directory, `terraform.tfstate` and `terraform.tfstate.backup`, and any `*.tfvars` files that might contain sensitive values.

---

## Best Practices

This module is designed as a reference implementation of Terraform and AWS best practices.

**Infrastructure as Code** — Every resource is declared in version-controlled Terraform files. There are no manual steps, no ClickOps, no configuration drift. The infrastructure is reproducible from scratch with a single `terraform apply`.

**Reusability** — The module is parameterised. The same HCL provisions a development bucket and a production distribution by changing variable values. Teams can reference the module from multiple root configurations without duplicating code.

**Modularity** — The module has a single responsibility: CloudFront + S3 static hosting. It is intentionally framework-agnostic and does not attempt to manage DNS, certificates, or WAF rules. These concerns are left to the consuming configuration, allowing this module to be composed with others.

**Security by default** — Insecure configurations require deliberate opt-out, not opt-in. The bucket is private by default. HTTPS is enforced by default. Public access is blocked by default. A new consumer gets a secure deployment without needing to know the security implications of each setting.

**Least Privilege** — The S3 bucket policy grants the minimum permissions required for CloudFront to serve content. No other permissions are granted. No wildcard principals are used.

**Documentation** — Every variable, output, and resource is documented. This README is designed to serve as both operational documentation and a learning resource.

**Semantic Versioning** — Module versions follow [semver](https://semver.org). Breaking changes increment the major version, new features increment the minor version, and bug fixes increment the patch version. Consumers can pin to a specific version for stability.

**Open Source Development** — The module is structured for open-source publication: a clear license, a contribution guide, an examples directory, and documentation that explains the why, not just the what.

**Terraform Registry conventions** — The repository and module structure follow the [official Terraform Registry module requirements](https://developer.hashicorp.com/terraform/registry/modules/publish): a three-part name, a `main.tf` / `variables.tf` / `outputs.tf` structure, and an `examples/` directory.

---

## Roadmap

The following features are planned for future module versions. Contributions are welcome.

| Feature | Description |
|---|---|
| 🌐 **Custom Domain Support** | Allow consumers to provide a custom domain name for the CloudFront distribution |
| 🔑 **ACM Certificate Integration** | Automatically provision or attach an ACM certificate for TLS on custom domains |
| 🗺️ **Route 53 Integration** | Optionally create a Route 53 alias record pointing to the CloudFront distribution |
| 📋 **CloudFront Access Logging** | Enable access logging to an S3 bucket for traffic analysis and debugging |
| 🛡️ **AWS WAF Integration** | Attach a Web ACL to the distribution to block malicious traffic patterns |
| 🔀 **Multiple Origins** | Support multiple S3 origins with path-based routing for micro-frontend architectures |
| 🔄 **Cache Invalidation Helper** | Output a ready-to-use `aws cloudfront create-invalidation` command after each apply |
| 🚀 **CI/CD Examples** | Add GitHub Actions workflow examples for build, sync, and invalidation across common frameworks |
| 🗃️ **S3 Object Versioning** | Optionally enable S3 versioning for rollback support |
| 📦 **Custom Cache Policies** | Expose granular cache policy configuration for advanced caching strategies |

---

## Contributing

Contributions are welcome. Please follow the standard open-source contribution workflow.

**1. Fork the repository**

Click the **Fork** button on GitHub to create a copy of this repository under your own account.

**2. Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

Use a descriptive branch name that reflects the change: `feature/add-waf-support`, `fix/oac-signing-behaviour`, `docs/improve-spa-section`.

**3. Make your changes**

Follow the existing code style. Keep `main.tf`, `variables.tf`, and `outputs.tf` focused on their responsibilities. Add or update documentation for any new variables or outputs. If you are adding a significant feature, consider adding or extending the `examples/basic/` configuration.

**4. Test your changes**

Run `terraform fmt` to ensure consistent formatting:

```bash
terraform fmt -recursive
```

Run `terraform validate` from the module root to catch configuration errors:

```bash
terraform init
terraform validate
```

If you have access to an AWS account, run the examples against a real environment before submitting.

**5. Commit with a clear message**

```bash
git commit -m "feat: add support for custom CloudFront price class"
```

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format where possible: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.

**6. Push and open a Pull Request**

```bash
git push origin feature/your-feature-name
```

Open a Pull Request against the `main` branch. Describe what the change does, why it is needed, and how it was tested. Reference any related issues with `Closes #<issue-number>`.

---

## License

MIT — see [LICENSE](./LICENSE) for details.