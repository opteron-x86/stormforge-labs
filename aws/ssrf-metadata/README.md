# URL Inspector Service

**Difficulty:** 2
**Description:** Exploit SSRF vulnerability to access EC2 metadata and exfiltrate S3 data  
**Estimated Time:** 45-60 minutes

## Overview

Internal Flask-based web service for testing HTTP/HTTPS endpoint accessibility. Deployed on EC2 with IAM role permissions, S3 data storage, and CloudTrail logging.

The service accepts URL parameters and returns accessibility status. It's exposed on port 8080 and designed for internal developer use.

## Learning Objectives

- Identify and exploit Server-Side Request Forgery (SSRF) vulnerabilities
- Access EC2 instance metadata service (IMDSv1)
- Extract IAM role credentials from metadata
- Assume IAM roles for privilege escalation
- Enumerate and access S3 buckets
- Exfiltrate sensitive data using stolen credentials

## Scenario

You've discovered a URL checking service running on an EC2 instance. The service allows you to test the accessibility of any URL by providing it as a parameter.

Your goal is to exploit the service to access the EC2 metadata endpoint, extract temporary credentials, escalate privileges, and retrieve sensitive customer data from S3.

## Architecture

- EC2 instance running Flask application on port 8080
- IAM instance profile with S3, SSM, and role assumption permissions
- S3 bucket containing customer data and API keys
- CloudTrail logging enabled for audit compliance
- IMDSv1 metadata service enabled

## Attack Surface

**Web Service Endpoint:**
```
GET /check?url=<target_url>
```

**Available from outputs:**
- Service URL
- SSH connection string
- S3 bucket name
- Instance role name
- CloudTrail bucket

## Key Concepts

### Server-Side Request Forgery (SSRF)

SSRF allows attackers to make requests from the vulnerable server to internal resources not directly accessible. Common targets:
- EC2 metadata: `http://169.254.169.254/latest/meta-data/`
- Internal services on localhost or private networks
- Cloud provider APIs and metadata endpoints

### EC2 Instance Metadata Service

IMDSv1 provides instance information without authentication:
- Instance identity and tags
- IAM role credentials at `/latest/meta-data/iam/security-credentials/`
- User data and network configuration
- No authentication required for IMDSv1

### IAM Role Credentials

EC2 instances with IAM roles receive temporary credentials:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- Credentials auto-rotate and expire after ~6 hours

## Hints

<details>
<summary>Hint 1: Testing the Service</summary>

Start by testing normal functionality with external URLs, then try accessing internal services:
```
http://169.254.169.254/latest/meta-data/
http://localhost
http://127.0.0.1
```
</details>

<details>
<summary>Hint 2: Metadata Enumeration</summary>

The metadata service is hierarchical. Navigate through directories:
- `/latest/meta-data/` - Start here
- `/latest/meta-data/iam/` - IAM information
- `/latest/meta-data/iam/security-credentials/` - List roles
- `/latest/meta-data/iam/security-credentials/<role-name>` - Get credentials
</details>

<details>
<summary>Hint 3: Using Stolen Credentials</summary>

Configure AWS CLI with extracted credentials:
```bash
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
export AWS_SESSION_TOKEN=<token>
```

Then enumerate permissions and resources.
</details>

<details>
<summary>Hint 4: Finding Sensitive Data</summary>

Check SSM parameters for hints about additional resources:
```bash
aws ssm describe-parameters
aws ssm get-parameter --name <parameter-name>
```

Look for references to IAM roles or S3 buckets in the configuration.
</details>

## Success Criteria

✓ Exploit SSRF to access EC2 metadata service  
✓ Extract IAM role credentials from metadata endpoint  
✓ Identify additional IAM roles with elevated permissions  
✓ Assume the data processor role  
✓ Access the S3 bucket containing customer data  
✓ Retrieve the flag from customer records

## Common Pitfalls

- Forgetting to include session token when using temporary credentials
- Not URL-encoding special characters in metadata paths
- Attempting to use expired credentials
- Missing the role assumption capability in the initial role's permissions

## Remediation

**Prevent SSRF:**
- Validate and sanitize URL inputs
- Use allowlists for permitted domains/IPs
- Block access to metadata IP ranges (169.254.169.254)
- Implement network egress filtering

**Metadata Service Security:**
- Enable IMDSv2 (requires session tokens)
- Set `http_tokens = "required"` in metadata options
- Limit hop count for containers

**IAM Best Practices:**
- Follow principle of least privilege
- Restrict role assumption to specific principals
- Use resource-based policies with conditions
- Implement SCPs for organizational guardrails

**Data Protection:**
- Enable S3 bucket encryption
- Use S3 Block Public Access
- Implement least-privilege bucket policies
- Enable MFA delete for critical buckets