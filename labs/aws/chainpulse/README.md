# ChainPulse - SSRF to Cloud Credential Theft

**Difficulty:** 5  
**Time:** 60-90 minutes  
**Prerequisites:** HTTP basics, AWS CLI, SSRF concepts, basic SQL

## Scenario

You've discovered an internal price oracle aggregator used by a cryptocurrency trading platform. The application validates external oracle endpoints before adding them to the price feed pool used for trade execution. Your objective is to exploit this functionality to access internal cloud resources and exfiltrate sensitive trading data from the backend database.

## Objectives

1. Identify the SSRF vulnerability in the oracle validation endpoint
2. Exploit SSRF to access EC2 Instance Metadata Service (IMDS)
3. Obtain IAM role credentials from the metadata service
4. Enumerate AWS Secrets Manager for stored credentials
5. Retrieve database credentials from Secrets Manager
6. Connect to the PostgreSQL database and exfiltrate wallet data

## Attack Surface

Access the application at `http://[instance-ip]:8080`

The oracle aggregator provides:
- Web interface for oracle management
- API endpoint for validating external oracle URLs
- Backend database storing wallet addresses, balances, and API keys

## Enumeration Checklist

### Phase 1: Application Reconnaissance
- What functionality does the oracle validation endpoint provide?
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
- What wallet data is stored?
- Where are the API keys and private keys?

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
│                            │ 6. Query wallet and API key data               │
│                            ▼                                                │
│                      FINANCIAL DATA                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

The database is in a private subnet and only accessible from the application tier. After obtaining credentials, use SSM Session Manager to access the EC2 instance, then connect to the database.

## Real-World Context

Price oracle manipulation and SSRF attacks are significant threats in the DeFi ecosystem. Attackers have exploited similar vulnerabilities to:

- Steal funds by manipulating price feeds before trade execution
- Access hot wallet private keys stored in cloud infrastructure  
- Drain liquidity pools by exploiting oracle trust assumptions

This lab demonstrates how a seemingly innocuous "URL validation" feature can lead to complete infrastructure compromise.

## Detection Opportunities

- IMDSv1 access patterns (should be using IMDSv2 with session tokens)
- Secrets Manager API calls from unexpected principals
- Database connections from non-application sources
- Outbound requests to internal IP ranges from web applications
