# Contributing Labs

## Lab Structure

Each lab must contain:

```
{provider}/lab-name/
├── README.md       # Required: description, objectives, techniques
├── main.tf         # Required: primary configuration
├── variables.tf    # Required: input variables
├── outputs.tf      # Required: outputs for attack scripts
└── versions.tf     # Required: provider versions
```

## Naming

- Use lowercase with hyphens: `ssrf-metadata`, `iam-privesc`
- Be descriptive but concise
- Prefix CVE labs with the CVE ID: `cve-2024-1234-exploit`

## README Template

```markdown
# Lab Name

Brief description of what this lab deploys and the vulnerability it demonstrates.

## Objectives

- First learning objective
- Second learning objective

## MITRE ATT&CK

- T1234 - Technique Name
- T1234.001 - Sub-technique Name

## Architecture

Describe the deployed resources and their relationships.

## Walkthrough

Step-by-step guide to exploit the vulnerability.

## Cleanup

Any manual cleanup steps if needed (usually handled by `sf destroy`).

## References

- Link to relevant documentation
- Link to CVE if applicable
```

## versions.tf Template

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "local" {}
}
```

## variables.tf Requirements

Always include these standard variables:

```hcl
variable "lab_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "sf"
}

variable "default_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
```

Provider-specific variables:

```hcl
# AWS
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "allowed_source_ips" {
  description = "IPs allowed to access lab resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Azure
variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# GCP
variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}
```

## outputs.tf Requirements

Export values needed for attack scripts:

```hcl
output "target_url" {
  description = "URL to target"
  value       = aws_instance.target.public_ip
}

output "credentials" {
  description = "Initial access credentials"
  value       = random_password.initial.result
  sensitive   = true
}
```

## Testing

Before submitting:

1. `terraform fmt -recursive` - Format code
2. `terraform validate` - Check syntax
3. `sf deploy {provider}/lab-name` - Test deployment
4. Complete the walkthrough manually
5. `sf destroy {provider}/lab-name` - Verify clean teardown

## Pull Request

- One lab per PR
- Include screenshots in README if helpful
- List estimated cloud costs in PR description
