---
name: aws-security-audit
description: >
  AWS security audit reference covering network security, encryption patterns,
  logging and monitoring, compliance frameworks (CIS, SOC2, PCI-DSS), Security Hub
  and GuardDuty finding interpretation, S3 bucket security, and prioritized
  remediation checklists. Complements aws-iam-best-practices which covers IAM-specific
  patterns. Load this skill for security audits, compliance reviews, and threat analysis.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: reference
---

# AWS Security Audit Reference

Comprehensive security audit reference covering network security, encryption, logging, compliance frameworks, and threat detection service interpretation. For IAM-specific patterns (policies, roles, SCPs, permission boundaries), load the companion `aws-iam-best-practices` skill instead.

---

## 1. Network Security Assessment

### Security Group Audit Checklist

**Critical findings (immediate remediation):**
- Ingress `0.0.0.0/0` on management ports (22/SSH, 3389/RDP, 5432/Postgres, 3306/MySQL, 27017/MongoDB)
- Ingress `0.0.0.0/0` on all ports (`-1` protocol or port range `0-65535`)
- Egress `0.0.0.0/0` on all ports from database or sensitive workloads

**High findings:**
- Ingress from broad CIDRs (`/8`, `/16`) that should be narrower
- Security groups referencing themselves without clear justification
- Unused security groups still attached to ENIs (attack surface)

**Acceptable patterns:**
- Ingress `0.0.0.0/0` on port 443/80 for public-facing ALBs
- Ingress from specific security group IDs (service-to-service)
- Ingress from VPC CIDR for internal communication

### CLI Commands for Security Group Audit

```bash
# Find security groups open to the internet
aws ec2 describe-security-groups --profile <profile> --region <region> \
  --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" \
  --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName,VPC:VpcId}'

# Find security groups open to the internet on SSH
aws ec2 describe-security-groups --profile <profile> --region <region> \
  --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" "Name=ip-permission.from-port,Values=22" \
  --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName}'

# Find unused security groups (no attached ENIs)
aws ec2 describe-network-interfaces --profile <profile> --region <region> \
  --query 'NetworkInterfaces[*].Groups[*].GroupId' --output text | tr '\t' '\n' | sort -u > /tmp/used-sgs.txt
aws ec2 describe-security-groups --profile <profile> --region <region> \
  --query 'SecurityGroups[*].GroupId' --output text | tr '\t' '\n' | sort -u > /tmp/all-sgs.txt
comm -23 /tmp/all-sgs.txt /tmp/used-sgs.txt
```

### VPC Design Security Assessment

**Verify these are in place:**

| Control | What to Check | Severity if Missing |
|---------|--------------|-------------------|
| VPC flow logs | `describe-flow-logs` — logs enabled for all VPCs | High |
| Private subnets | Database/compute in subnets without IGW route | Critical |
| NAT Gateway | Private subnets route through NAT, not IGW | High |
| VPC endpoints | S3, DynamoDB, KMS, STS accessed via endpoints | Medium |
| DNS settings | `enableDnsHostnames` and `enableDnsSupport` both true | Medium |
| Default VPC | Default VPC should have no resources or be deleted | Low |

### NACL Assessment

NACLs provide stateless defense-in-depth. Check:
- Default NACL should NOT allow all traffic (many accounts leave this open)
- Custom NACLs should deny known-bad ports at the subnet level
- Ephemeral port ranges (1024-65535) must be allowed for return traffic

---

## 2. Encryption Assessment

### At-Rest Encryption Checklist

| Service | How to Check | Default | Required |
|---------|-------------|---------|----------|
| S3 | `get-bucket-encryption` | SSE-S3 (since Jan 2023) | SSE-KMS for sensitive data |
| RDS/Aurora | `describe-db-instances` → `StorageEncrypted` | Opt-in | Always enable (can't add later) |
| DynamoDB | `describe-table` → `SSEDescription` | AWS-owned key | CMK for sensitive data |
| EBS | `describe-volumes` → `Encrypted` | Account default (check `get-ebs-encryption-by-default`) | Always enable |
| EFS | `describe-file-systems` → `Encrypted` | Opt-in | Always enable |
| SQS | `get-queue-attributes` → `KmsMasterKeyId` | None | SSE-SQS or SSE-KMS |
| SNS | `get-topic-attributes` → `KmsMasterKeyId` | None | SSE-KMS for sensitive topics |
| ElastiCache | `describe-replication-groups` → `AtRestEncryptionEnabled` | Opt-in | Always enable |
| OpenSearch | `describe-domain` → `EncryptionAtRestOptions` | Opt-in | Always enable |
| Secrets Manager | Always encrypted with KMS | AWS-managed key | CMK for cross-account |
| CloudWatch Logs | `describe-log-groups` → `kmsKeyId` | AWS-managed | CMK for sensitive logs |

### In-Transit Encryption Checklist

| Service | What to Check | Severity if Missing |
|---------|--------------|-------------------|
| ALB/NLB listeners | HTTPS (443) listener, no HTTP without redirect | Critical |
| RDS connections | `require_ssl` parameter, certificate authority | High |
| ElastiCache | `TransitEncryptionEnabled` | High |
| OpenSearch | `NodeToNodeEncryptionOptions`, HTTPS endpoint | High |
| S3 | Bucket policy with `aws:SecureTransport` condition | Medium |
| API Gateway | Always HTTPS (enforced by service) | N/A |

### KMS Key Audit

```bash
# List all CMKs
aws kms list-keys --profile <profile> --region <region>

# Check rotation status for each key
aws kms get-key-rotation-status --key-id <key-id> --profile <profile> --region <region>

# Check key policy (who can use/manage the key)
aws kms get-key-policy --key-id <key-id> --policy-name default --profile <profile> --region <region>
```

**KMS findings to look for:**
- Keys without automatic rotation enabled (should rotate annually)
- Key policies granting `kms:*` to broad principals
- Keys with `"Principal": "*"` in the policy (public access)
- Disabled or scheduled-for-deletion keys still referenced by resources

---

## 3. Logging and Monitoring Assessment

### Logging Completeness Checklist

| Log Source | How to Verify | Severity if Missing |
|-----------|--------------|-------------------|
| CloudTrail (management events) | `describe-trails` — enabled in all regions | Critical |
| CloudTrail (data events) | Check `get-event-selectors` — S3/Lambda data events | High for sensitive buckets |
| CloudTrail log file validation | `IsLogFileValidationEnabled` | High |
| CloudTrail multi-region | `IsMultiRegionTrail` | High |
| S3 access logging | `get-bucket-logging` for sensitive buckets | Medium |
| VPC flow logs | `describe-flow-logs` for all VPCs | High |
| ALB access logs | `describe-load-balancer-attributes` → `access_logs.s3.enabled` | Medium |
| CloudFront access logs | `get-distribution` → `Logging` | Medium |
| RDS audit logging | `describe-db-parameters` → `log_statement`, `pgaudit` | Medium |
| Lambda function logging | Always on (verify log group exists) | Low |

### CloudWatch Alarms Security Checklist

These alarms should exist in production accounts (CIS Benchmark aligned):

| Alarm | Metric Filter Pattern | CIS Control |
|-------|----------------------|-------------|
| Root account login | `{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }` | 1.7 |
| Console login without MFA | `{ $.eventName = "ConsoleLogin" && $.additionalEventData.MFAUsed != "Yes" }` | 1.6 |
| IAM policy changes | `{ $.eventName = "DeleteGroupPolicy" \|\| $.eventName = "DeleteRolePolicy" \|\| $.eventName = "DeleteUserPolicy" \|\| $.eventName = "PutGroupPolicy" \|\| $.eventName = "PutRolePolicy" \|\| $.eventName = "PutUserPolicy" \|\| ... }` | 4.4 |
| CloudTrail config changes | `{ $.eventName = "CreateTrail" \|\| $.eventName = "UpdateTrail" \|\| $.eventName = "DeleteTrail" \|\| $.eventName = "StartLogging" \|\| $.eventName = "StopLogging" }` | 4.5 |
| S3 bucket policy changes | `{ $.eventSource = "s3.amazonaws.com" && ($.eventName = "PutBucketAcl" \|\| $.eventName = "PutBucketPolicy" \|\| ...) }` | 4.8 |
| Security group changes | `{ $.eventName = "AuthorizeSecurityGroupIngress" \|\| $.eventName = "AuthorizeSecurityGroupEgress" \|\| $.eventName = "RevokeSecurityGroupIngress" \|\| $.eventName = "RevokeSecurityGroupEgress" \|\| $.eventName = "CreateSecurityGroup" \|\| $.eventName = "DeleteSecurityGroup" }` | 4.10 |
| NACL changes | `{ $.eventName = "CreateNetworkAcl" \|\| $.eventName = "CreateNetworkAclEntry" \|\| $.eventName = "DeleteNetworkAcl" \|\| $.eventName = "DeleteNetworkAclEntry" \|\| $.eventName = "ReplaceNetworkAclEntry" \|\| $.eventName = "ReplaceNetworkAclAssociation" }` | 4.11 |
| VPC changes | `{ $.eventName = "CreateVpc" \|\| $.eventName = "DeleteVpc" \|\| $.eventName = "ModifyVpcAttribute" \|\| $.eventName = "AcceptVpcPeeringConnection" \|\| ... }` | 4.14 |

---

## 4. S3 Bucket Security Deep Dive

### Audit Checklist (per bucket)

```bash
BUCKET="my-bucket"
PROFILE="my-profile"

# Public access block (account-level)
aws s3control get-public-access-block --account-id <account-id> --profile $PROFILE

# Public access block (bucket-level)
aws s3api get-public-access-block --bucket $BUCKET --profile $PROFILE

# Bucket policy
aws s3api get-bucket-policy --bucket $BUCKET --profile $PROFILE

# Bucket ACL (legacy — should be "BucketOwnerEnforced")
aws s3api get-bucket-acl --bucket $BUCKET --profile $PROFILE

# Object ownership (should be "BucketOwnerEnforced" to disable ACLs)
aws s3api get-bucket-ownership-controls --bucket $BUCKET --profile $PROFILE

# Encryption
aws s3api get-bucket-encryption --bucket $BUCKET --profile $PROFILE

# Versioning
aws s3api get-bucket-versioning --bucket $BUCKET --profile $PROFILE

# Logging
aws s3api get-bucket-logging --bucket $BUCKET --profile $PROFILE

# Lifecycle rules
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET --profile $PROFILE

# CORS (should only be set if needed)
aws s3api get-bucket-cors --bucket $BUCKET --profile $PROFILE
```

### S3 Security Findings Severity

| Finding | Severity | Notes |
|---------|----------|-------|
| Public bucket (ACL or policy) | **Critical** | Verify intentional — most should NOT be public |
| No encryption (pre-2023 bucket) | **High** | Enable SSE-S3 minimum, SSE-KMS for sensitive |
| No versioning on critical data | **High** | Protects against accidental deletion and ransomware |
| No access logging on sensitive buckets | **Medium** | Required for audit trail |
| ACLs not disabled (ObjectOwnership != BucketOwnerEnforced) | **Medium** | Legacy ACLs are a common misconfiguration vector |
| No lifecycle policy | **Low** | Cost concern, not security (unless retention is required) |
| CORS misconfigured (`*` origin) | **Medium** | Can enable cross-site data theft |

---

## 5. Security Hub Finding Interpretation

### Severity Mapping

Security Hub normalizes findings to these severities:

| Label | Score Range | Response Time |
|-------|-----------|---------------|
| CRITICAL | 90-100 | Immediate — drop everything |
| HIGH | 70-89 | Within 24 hours |
| MEDIUM | 40-69 | Within 1 week |
| LOW | 1-39 | Next sprint/cycle |
| INFORMATIONAL | 0 | Acknowledge, no action required |

### Common Security Hub Findings and Remediation

**CIS AWS Foundations Benchmark:**

| Control | Finding | Quick Remediation |
|---------|---------|-------------------|
| 1.4 | Root account access key exists | Delete root access keys immediately |
| 1.5 | MFA not enabled for root | Enable hardware MFA for root |
| 1.10 | IAM password policy insufficient | Set minimum 14 chars, require all types |
| 2.1 | CloudTrail not enabled | Enable multi-region trail with validation |
| 2.6 | S3 bucket access logging not enabled on CloudTrail bucket | Enable access logging |
| 3.1-3.14 | Missing CloudWatch metric filters/alarms | Create metric filters (see Section 3) |
| 4.1 | Security group allows unrestricted ingress on port 22 | Restrict to VPN CIDR |
| 4.3 | Default security group allows traffic | Remove all rules from default SG |

**AWS Foundational Security Best Practices (FSBP):**

| Control | Finding | Quick Remediation |
|---------|---------|-------------------|
| EC2.19 | Security group unrestricted common ports | Restrict ingress to known CIDRs |
| IAM.1 | IAM policies with full admin access | Scope down to least privilege |
| RDS.3 | RDS instance not encrypted | Cannot add encryption to existing — recreate |
| S3.2 | S3 bucket public read access | Enable public access block |
| Lambda.1 | Lambda function policy overly permissive | Remove `Principal: *` from resource policy |

### Filtering Security Hub Findings

```bash
# Active critical/high findings
aws securityhub get-findings --profile <profile> --region <region> \
  --filters '{
    "SeverityLabel": [{"Value": "CRITICAL", "Comparison": "EQUALS"}, {"Value": "HIGH", "Comparison": "EQUALS"}],
    "RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}],
    "WorkflowStatus": [{"Value": "NEW", "Comparison": "EQUALS"}, {"Value": "NOTIFIED", "Comparison": "EQUALS"}]
  }'

# Findings for a specific resource
aws securityhub get-findings --profile <profile> --region <region> \
  --filters '{
    "ResourceId": [{"Value": "<resource-arn>", "Comparison": "EQUALS"}],
    "RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}]
  }'

# Findings by compliance standard
aws securityhub get-findings --profile <profile> --region <region> \
  --filters '{
    "ComplianceSecurityControlId": [{"Value": "IAM.", "Comparison": "PREFIX"}],
    "RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}]
  }'
```

---

## 6. GuardDuty Finding Interpretation

### Finding Types by Threat Category

**Credential Compromise:**
| Type | Severity | What It Means |
|------|----------|--------------|
| `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS` | High | EC2 instance credentials used from outside AWS (exfiltrated) |
| `UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B` | Medium | Successful console login from unusual location |
| `UnauthorizedAccess:IAMUser/MaliciousIPCaller.Custom` | Medium | API call from a known-bad IP on your threat list |

**Cryptocurrency Mining:**
| Type | Severity | What It Means |
|------|----------|--------------|
| `CryptoCurrency:EC2/BitcoinTool.B!DNS` | High | EC2 instance querying crypto mining DNS |
| `CryptoCurrency:Runtime/BitcoinTool.B` | High | Runtime detected crypto mining process |

**Data Exfiltration:**
| Type | Severity | What It Means |
|------|----------|--------------|
| `Exfiltration:S3/AnomalousBehavior` | High | Unusual S3 API pattern suggesting data theft |
| `Exfiltration:S3/MaliciousIPCaller` | High | S3 accessed from known-bad IP |

**Recon / Scanning:**
| Type | Severity | What It Means |
|------|----------|--------------|
| `Recon:EC2/PortProbeUnprotectedPort` | Low | Port scan detected on an unprotected port |
| `Discovery:S3/AnomalousBehavior` | Low | Unusual S3 bucket enumeration pattern |

### GuardDuty Response Playbook

1. **Assess**: What type of finding? What resource is affected?
2. **Contain**: If credential compromise — rotate credentials immediately
3. **Investigate**: Use CloudTrail to trace what the compromised credential did
4. **Remediate**: Fix the vulnerability that allowed the compromise
5. **Recover**: Verify no persistence mechanisms (new IAM users, new access keys, backdoor policies)

---

## 7. Compliance Framework Quick Reference

### CIS AWS Foundations Benchmark v3.0 (Key Controls)

| Section | Focus | Key Checks |
|---------|-------|-----------|
| 1 | Identity and Access Management | Root MFA, no root access keys, password policy, no access keys for console users |
| 2 | Logging | CloudTrail multi-region with validation, Config enabled, S3 access logging |
| 3 | Monitoring | CloudWatch alarms for IAM changes, console logins, network changes |
| 4 | Networking | No unrestricted SSH/RDP, default SG restricts all, VPC flow logs |

### SOC 2 Mapping (AWS Controls)

| SOC 2 Trust Criteria | AWS Controls |
|----------------------|-------------|
| CC6.1 — Logical access | IAM policies, MFA, federation, password policy |
| CC6.3 — Access removal | IAM user lifecycle, access key rotation, credential report |
| CC6.6 — System boundaries | VPC security groups, NACLs, WAF, API Gateway |
| CC7.2 — System monitoring | CloudTrail, CloudWatch, GuardDuty, Security Hub |
| CC8.1 — Change management | CloudFormation/Terraform, Config rules, deployment pipelines |
| A1.2 — Availability | Multi-AZ, auto-scaling, backups, DR plan |

### PCI-DSS v4.0 Mapping (Relevant AWS Controls)

| Requirement | AWS Controls |
|-------------|-------------|
| 1 — Network security | Security groups, NACLs, WAF, VPC segmentation |
| 2 — Secure configurations | Config rules, SSM Patch Manager, hardened AMIs |
| 3 — Protect stored data | KMS encryption, S3 bucket policies, RDS encryption |
| 4 — Encrypt transmissions | TLS on ALB/NLB, RDS SSL, ElastiCache TLS |
| 7 — Restrict access | IAM least privilege, MFA, permission boundaries |
| 8 — Identify users | IAM users/roles, federation, CloudTrail identity |
| 10 — Log and monitor | CloudTrail, CloudWatch Logs, VPC flow logs |
| 11 — Test security | GuardDuty, Inspector, penetration testing |

---

## 8. Remediation Priority Framework

When producing a remediation roadmap, use this priority matrix:

### Priority Calculation

```
Priority Score = Severity × Exploitability × Environment Weight
```

| Factor | Values |
|--------|--------|
| Severity | Critical=4, High=3, Medium=2, Low=1 |
| Exploitability | Internet-facing=3, Internal=2, Requires auth=1 |
| Environment | Production=3, Staging=2, Dev=1 |

### Suggested Timeline by Priority Score

| Score | Timeline | Example |
|-------|----------|---------|
| 27-36 | **Immediate** (same day) | Critical + Internet-facing + Production |
| 12-26 | **Urgent** (within 48h) | High + Internal + Production |
| 6-11 | **Planned** (within 1 week) | Medium + Internet-facing + Staging |
| 1-5 | **Backlog** (next sprint) | Low + Requires auth + Dev |

### Quick Wins (Low Effort, High Impact)

These remediation actions typically take < 1 hour and significantly improve security:

1. **Enable S3 public access block** at the account level
2. **Enable EBS default encryption** at the account level
3. **Restrict default security group** — remove all inbound/outbound rules
4. **Enable CloudTrail log file validation** — one CLI command
5. **Enable MFA for root** — 5 minutes with a virtual MFA device
6. **Delete root access keys** — immediate, irreversible improvement
7. **Enable AWS Config** — foundational for compliance tracking
8. **Enable GuardDuty** — immediate threat detection with no config needed
9. **Block public S3 buckets** — `s3control put-public-access-block`
10. **Enable KMS key rotation** — one API call per key
