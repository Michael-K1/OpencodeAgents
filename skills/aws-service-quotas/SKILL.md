---
description: >
  Comprehensive AWS service quotas and limits reference. Covers compute,
  networking, storage, database, messaging, security, and serverless service
  limits. Includes default and maximum values, tips for when you're
  approaching limits, and how to request increases. Load this skill when
  designing architecture, sizing resources, or troubleshooting limit errors.
---

# AWS Service Quotas & Limits Reference

## How to Check Quotas Programmatically

```bash
# List all quotas for a service
aws service-quotas list-service-quotas --service-code <code> --profile <profile>

# Get a specific quota
aws service-quotas get-service-quota --service-code <code> --quota-code <code> --profile <profile>

# Check current utilization (if supported)
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A --profile <profile>

# Request an increase
aws service-quotas request-service-quota-increase --service-code <code> --quota-code <code> --desired-value <N>
```

Common service codes: `ec2`, `elasticloadbalancing`, `ecs`, `lambda`, `rds`, `s3`, `dynamodb`, `sqs`, `sns`, `iam`, `cloudformation`, `apigateway`, `cloudfront`, `route53`, `kms`, `secretsmanager`

---

## Compute

### EC2

| Resource | Default Limit | Max / Notes |
|---|---|---|
| On-Demand instances | Varies by type (vCPU-based) | Request increase via quota |
| Spot instances | Varies by type (vCPU-based) | Request increase |
| Elastic IPs per region | 5 | Increasable |
| Key pairs per region | 5,000 | Hard limit |
| Placement groups per region | 500 | Increasable |
| AMIs per region | 50,000 | Increasable |
| EBS volumes per region | 5,000 | Increasable |
| EBS snapshots per region | 100,000 | Increasable |
| EBS volume size (gp3/gp2) | 16 TiB | Hard limit |
| EBS IOPS (gp3) | 16,000 | Hard limit |
| EBS IOPS (io2) | 256,000 (with Block Express) | Hard limit |
| EBS throughput (gp3) | 1,000 MiB/s | Hard limit |

### ECS (Fargate)

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Clusters per region | 10,000 | Increasable |
| Services per cluster | 5,000 | Increasable |
| Tasks per service | 5,000 | Hard limit |
| Tasks (RUNNING) per region | 3,000 Fargate / 3,000 Fargate Spot | Increasable |
| Container instances per cluster | 5,000 (EC2 launch type) | Increasable |
| Task definition size | 64 KiB | Hard limit |
| Task definition revisions per family | No limit | — |
| Containers per task definition | 10 | Hard limit |
| vCPU per task | 0.25 - 16 | Hard limit |
| Memory per task | 0.5 - 120 GiB | Hard limit |
| Ephemeral storage per task | 20 - 200 GiB | Hard limit (default: 20 GiB) |
| ENIs per subnet (Fargate) | Subnet IP limit | — |
| Tags per resource | 50 | Hard limit |
| Container port range | 1 - 65535 | — |
| Environment variables per container | 500 | Hard limit |
| Secrets per container | 500 | Hard limit |

**vCPU / Memory valid combinations:**

| vCPU | Memory Range |
|---|---|
| 0.25 | 0.5, 1, 2 GiB |
| 0.5 | 1 - 4 GiB (1 GiB increments) |
| 1 | 2 - 8 GiB (1 GiB increments) |
| 2 | 4 - 16 GiB (1 GiB increments) |
| 4 | 8 - 30 GiB (1 GiB increments) |
| 8 | 16 - 60 GiB (4 GiB increments) |
| 16 | 32 - 120 GiB (8 GiB increments) |

### Lambda

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Concurrent executions per region | 1,000 | Increasable (commonly to 10,000+) |
| Function timeout | 15 minutes | Hard limit |
| Memory allocation | 128 MB - 10,240 MB | 1 MB increments |
| Ephemeral storage (/tmp) | 512 MB - 10,240 MB | Hard limit |
| Deployment package (zip) | 50 MB (direct) / 250 MB (S3 unzipped) | Hard limit |
| Container image size | 10 GB | Hard limit |
| Environment variable size (total) | 4 KB | Hard limit |
| Layers per function | 5 | Hard limit |
| Layer size (unzipped) | 250 MB | Hard limit |
| Burst concurrency | 500 - 3,000 (varies by region) | Region-dependent |
| Provisioned concurrency | Per function, up to account limit | Increasable |
| Function versions | No limit | — |
| Function aliases | No limit | — |
| Invocation payload (sync) | 6 MB | Hard limit |
| Invocation payload (async) | 256 KB | Hard limit |
| Response streaming payload | 20 MB | Hard limit |

---

## Networking

### VPC

| Resource | Default Limit | Max / Notes |
|---|---|---|
| VPCs per region | 5 | Increasable to 100+ |
| Subnets per VPC | 200 | Increasable |
| IPv4 CIDR blocks per VPC | 5 | Increasable to 50 |
| Route tables per VPC | 200 | Increasable |
| Routes per route table | 50 | Increasable to 1,000 |
| Internet gateways per region | 5 | Tied to VPC limit |
| NAT gateways per AZ | 5 | Increasable |
| NAT gateway bandwidth | 100 Gbps | Hard limit |
| NAT gateway per-flow limit | 55,000 connections per destination | Hard limit — use multiple NAT GWs for high throughput |
| VPC endpoints per region | 50 (Gateway), 50 (Interface) | Increasable |
| VPC peering connections per VPC | 50 | Increasable to 125 |
| Network interfaces per region | 5,000 | Increasable |
| Elastic IPs per region | 5 | Increasable |

### Security Groups

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Security groups per VPC | 2,500 | Increasable |
| Inbound rules per SG | 60 | Increasable (SG rules × SGs per ENI ≤ 1,000) |
| Outbound rules per SG | 60 | Same constraint |
| Security groups per ENI | 5 | Increasable to 16 |
| **Total rules limit** | SG rules × SGs per ENI ≤ 1,000 | Hard constraint |

### Elastic Load Balancing

| Resource | Default Limit | Max / Notes |
|---|---|---|
| ALBs per region | 50 | Increasable |
| NLBs per region | 50 | Increasable |
| Target groups per region | 3,000 | Increasable |
| Targets per target group | 1,000 | Hard limit |
| Listeners per ALB | 50 | Hard limit |
| Rules per ALB listener | 100 (+1 default) | Increasable to 200 |
| Certificates per ALB listener | 25 (+1 default) | Increasable |
| Target groups per ALB action | 5 (weighted) | Hard limit |
| Condition values per rule | 5 | Hard limit |
| ALB idle timeout | 1 - 4,000 seconds | Default: 60s |
| ALB connection timeout (to target) | — | Default: no limit |
| NLB cross-zone LB | Enabled per target group | — |

### Route53

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Hosted zones per account | 500 | Increasable |
| Records per hosted zone | 10,000 | Increasable |
| Health checks per account | 200 | Increasable |
| Reusable delegation sets | 100 | Hard limit |
| Traffic policies | 50 | Increasable |
| Queries per second (per hosted zone) | No hard limit | Soft limit: Route53 can handle millions QPS |

### CloudFront

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Distributions per account | 200 | Increasable |
| Alternate domain names (CNAMEs) per distribution | 100 | Increasable |
| Origins per distribution | 25 | Increasable |
| Cache behaviors per distribution | 25 | Increasable |
| Origin groups per distribution | 10 | Hard limit |
| SSL certificates per account | 100 | Increasable |
| Custom headers per origin | 10 | Hard limit |
| Whitelisted headers per cache behavior | 10 | Hard limit |
| Lambda@Edge concurrent executions | 1,000 per region | Increasable |
| CloudFront Functions | 100 per account | Increasable |
| Max file size (single GET) | 30 GB | Hard limit |
| Request body size (POST/PUT) | 20 GB | Hard limit |

### Global Accelerator

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Accelerators per account | 20 | Increasable |
| Listeners per accelerator | 10 | Increasable |
| Endpoint groups per listener | 10 | — |
| Endpoints per endpoint group | 10 | — |
| Port ranges per listener | 10 | — |

---

## Storage

### S3

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Buckets per account | 100 | Increasable to 1,000 |
| Object size (single PUT) | 5 GB | Use multipart for larger |
| Object size (multipart) | 5 TB | Hard limit |
| PUT requests per prefix | 3,500/s | Per prefix — distribute across prefixes |
| GET requests per prefix | 5,500/s | Per prefix |
| Lifecycle rules per bucket | 1,000 | Hard limit |
| Bucket policy size | 20 KB | Hard limit |
| Tags per object | 10 | Hard limit |
| Parts per multipart upload | 10,000 | Hard limit |
| Part size (multipart) | 5 MB - 5 GB | Hard limit |
| Replication rules per bucket | 1,000 | Hard limit |
| Event notification configs | 100 | Per bucket |

---

## Databases

### RDS / Aurora

| Resource | Default Limit | Max / Notes |
|---|---|---|
| DB instances per region | 40 | Increasable |
| Aurora clusters per region | 40 | Increasable |
| Read replicas per DB instance | 5 (RDS) / 15 (Aurora) | Hard limit |
| Manual snapshots per region | 100 | Increasable |
| Automated backup retention | 0 - 35 days | Hard limit: 35 days |
| Max storage (gp3) | 64 TiB | Hard limit |
| Max IOPS (gp3) | 16,000 | Hard limit |
| Max IOPS (io1/io2) | 256,000 (io2 Block Express) | Hard limit |
| Parameter groups per region | 50 | Increasable |
| Option groups per region | 20 | Increasable |
| Security groups per DB instance | 5 | Hard limit |
| DB subnet groups per region | 50 | Increasable |
| Subnets per DB subnet group | 20 | Hard limit |
| Event subscriptions per region | 20 | Increasable |
| Max connections (varies by instance) | Instance-class dependent | See lookup table below |
| Proxy connections (RDS Proxy) | 1,000 per proxy | Configurable |

**RDS PostgreSQL Max Connections by Instance Class:**

| Instance Class | Max Connections |
|---|---|
| db.t4g.medium | 405 |
| db.t4g.large | 901 |
| db.t4g.xlarge | 1,802 |
| db.t4g.2xlarge | 3,604 |
| db.t4g.4xlarge | 5,000 |
| db.r6id.large | 1,802 |
| db.r6id.xlarge | 3,604 |
| db.r6id.2xlarge | 5,000 |
| db.r7i.large | 1,802 |
| db.r7i.xlarge | 3,604 |
| db.r7i.2xlarge | 5,000 |

Formula: `LEAST(DBInstanceClassMemory/9531392, 5000)` for PostgreSQL.

### DocumentDB

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Clusters per region | 40 | Increasable |
| Instances per cluster | 16 | Hard limit |
| Manual snapshots per region | 100 | Increasable |
| DB subnet groups per region | 50 | Increasable |
| Document size | 16 MB | Hard limit (BSON) |
| Nested depth | 100 levels | Hard limit |
| Connections per instance | Instance-class dependent | See table below |

**DocumentDB Max Connections by Instance Class:**

| Instance Class | Max Connections |
|---|---|
| db.t3.medium | 1,000 |
| db.t4g.medium | 1,000 |
| db.r4.large | 1,700 |
| db.r4.xlarge | 3,400 |
| db.r5.large | 3,400 |
| db.r5.xlarge | 7,000 |
| db.r6g.large | 3,400 |
| db.r6g.xlarge | 7,000 |
| db.r6g.2xlarge | 14,200 |

### DynamoDB

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Tables per region | 2,500 | Increasable |
| Item size | 400 KB | Hard limit |
| Partition key length | 2,048 bytes | Hard limit |
| Sort key length | 1,024 bytes | Hard limit |
| Local secondary indexes per table | 5 | Hard limit (must be created at table creation) |
| Global secondary indexes per table | 20 | Increasable |
| Projected attributes per index | 100 | Hard limit |
| Throughput (on-demand) | 40,000 RCU / 40,000 WCU per table | Increasable |
| Throughput (provisioned) | 40,000 RCU / 40,000 WCU per table | Increasable |
| Batch operations | 25 items per BatchWriteItem, 100 items per BatchGetItem | Hard limit |
| Transaction items | 100 per TransactWriteItems/TransactGetItems | Hard limit |
| Query/Scan result size | 1 MB per call (paginate) | Hard limit |

### ElastiCache / Valkey

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Clusters per region | 50 | Increasable |
| Nodes per cluster (cluster mode disabled) | 6 (1 primary + 5 replicas) | Hard limit |
| Shards per cluster (cluster mode enabled) | 500 | Increasable |
| Replicas per shard | 5 | Hard limit |
| Parameter groups per region | 150 | Hard limit |
| Subnet groups per region | 150 | Increasable |
| Serverless cache max data | 5 TB | Per serverless cache |
| Serverless ECPU | 15,000,000 per second | Per serverless cache |
| Item size (max) | 512 MB | Hard limit (Redis/Valkey) |
| Connections per node | 65,000 | Hard limit |

### OpenSearch

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Domains per region | 100 | Increasable |
| Data nodes per domain | 80 (with dedicated masters) | Hard limit |
| Dedicated master nodes | 3 or 5 | Best practice: 3 |
| EBS volume size (gp3) | 16 TiB per node | Hard limit |
| Index size | No hard limit | Best practice: < 50 GB per shard |
| Shards per node | 1,000 (default) | Configurable |

---

## Messaging

### SQS

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Queues per region | Unlimited | — |
| Message size | 256 KB | Use S3 for larger (Extended Client) |
| Message retention | 1 minute - 14 days | Default: 4 days |
| Visibility timeout | 0 - 12 hours | Default: 30 seconds |
| Long poll wait time | 0 - 20 seconds | — |
| Batch operations | 10 messages per batch | Hard limit |
| In-flight messages (standard) | 120,000 | Per queue |
| In-flight messages (FIFO) | 20,000 | Per queue |
| FIFO throughput | 300 msg/s (3,000 with batching and high throughput mode) | Hard limit |
| Delay | 0 - 15 minutes | Per message or queue default |

### SNS

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Topics per region | 100,000 | Increasable |
| Subscriptions per topic | 12,500,000 | Hard limit |
| Message size | 256 KB | Hard limit |
| SMS spend per month | $1.00 (default) | Increasable |
| Filter policies per subscription | 1 | — |
| Filter policy size | 150 KB (if expanded) | Hard limit |

### Amazon MQ (ActiveMQ)

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Brokers per region | 20 | Increasable |
| Destinations per broker | 200 (single) / 100 (active/standby) | Best practice: keep < 50 active |
| Connections per broker | Instance-dependent | mq.m5.large: 1,000 |
| Message size | 100 MB | Hard limit, but keep < 10 MB |
| Storage per broker | 200 GB | Hard limit |

### EventBridge

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Rules per event bus | 300 | Increasable to 2,000 |
| Targets per rule | 5 | Hard limit |
| Event size | 256 KB | Hard limit |
| Invocations per second | 10,000+ (varies by target) | Increasable |
| Scheduled rules | 300 per region | Increasable |
| Event buses per region | 100 | Increasable |

---

## Security & Identity

### IAM

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Users per account | 5,000 | Hard limit |
| Groups per account | 300 | Hard limit |
| Roles per account | 1,000 | Increasable to 5,000 |
| Instance profiles per account | 1,000 | Increasable |
| Managed policies per account | 1,500 | Increasable |
| Managed policies per role/user | 10 | Increasable to 20 |
| Inline policy size per role | 10,240 characters | Hard limit |
| Managed policy size (per version) | 6,144 characters | Hard limit |
| Trust policy size | 2,048 characters | Hard limit |
| Access keys per user | 2 | Hard limit |
| MFA devices per user | 8 | Hard limit |
| SAML providers | 100 | Hard limit |
| OIDC providers | 100 | Hard limit |

### KMS

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Keys per region | 100,000 | Increasable |
| Aliases per key | 50 | Hard limit |
| Aliases per region | 100,000 | Hard limit |
| Grants per key | 50,000 | Hard limit |
| Key policy size | 32 KB | Hard limit |
| Cryptographic requests/second | 5,500 - 30,000 (varies by region and key type) | Increasable |
| `Encrypt`/`Decrypt`/`GenerateDataKey` | 5,500/s (symmetric, shared) | Region-dependent |
| `Sign`/`Verify` (RSA) | 500/s | Hard limit |

### ACM

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Certificates per region | 2,500 | Increasable |
| Domain names per certificate | 10 (SAN) | Increasable to 100 |
| Certificates per ALB listener | 25 (+1 default) | Increasable |
| Renewal period | Auto-renew 60 days before expiry | — |

### WAF

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Web ACLs per region | 100 | Increasable |
| Rules per web ACL | 1,500 WCU (capacity units) | — |
| IP sets per region | 100 | Increasable |
| IPs per IP set | 10,000 | Hard limit |
| Rate-based rule minimum | 100 requests per 5 min | — |
| Regex pattern sets per region | 10 | Increasable |
| Rule groups per region | 100 | Increasable |
| Managed rule group statement nesting | 1 level | Cannot nest managed groups |

### Secrets Manager

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Secrets per region | 500,000 | Hard limit |
| Secret value size | 65,536 bytes (64 KB) | Hard limit |
| Secret versions per secret | ~100 (AWS manages cleanup) | — |
| API requests per second | 5,000 | Increasable |
| Resource policy size | 20,480 bytes | Hard limit |

---

## API Gateway

### REST API (v1)

| Resource | Default Limit | Max / Notes |
|---|---|---|
| APIs per region | 600 | Increasable |
| Resources per API | 300 | Hard limit |
| Stages per API | 10 | Hard limit |
| API keys per account | 10,000 | Hard limit |
| Usage plans per account | 300 | Hard limit |
| Integration timeout | 50 ms - 29 seconds | Hard limit |
| Payload size | 10 MB | Hard limit |
| Throttle (account) | 10,000 RPS | Increasable |
| Throttle (per route, default) | 10,000 RPS | Configurable |
| Burst | 5,000 | Increasable |
| Custom domains per region | 120 | Increasable |

### HTTP API (v2)

| Resource | Default Limit | Max / Notes |
|---|---|---|
| APIs per region | 600 | Increasable |
| Routes per API | 300 | Increasable |
| Stages per API | 10 | Increasable |
| Integration timeout | 50 ms - 30 seconds | Hard limit |
| Payload size | 10 MB | Hard limit |
| Throttle (account) | 10,000 RPS | Increasable |

---

## CloudFormation

| Resource | Default Limit | Max / Notes |
|---|---|---|
| Stacks per region | 2,000 | Increasable |
| Resources per stack | 500 | Hard limit — use nested stacks |
| Outputs per stack | 200 | Hard limit |
| Parameters per stack | 200 | Hard limit |
| Mappings per stack | 200 | Hard limit |
| Template size (direct) | 51,200 bytes | Hard limit — use S3 |
| Template size (S3) | 1 MB | Hard limit |
| Stack sets per account | 100 | Increasable |
| Stack instances per stack set | 2,000 | Increasable |

---

## Tips for Approaching Limits

1. **Monitor quotas proactively**: Use AWS Service Quotas dashboard or `aws service-quotas` CLI
2. **Request increases early**: Some increases take hours/days for approval
3. **Design for limits**: Distribute S3 requests across prefixes, use SQS batching, pagination
4. **Use CloudWatch alarms on utilization**: Some services expose utilization metrics
5. **Check Trusted Advisor**: Free tier includes some service limit checks
6. **Document exceptions**: When you must use `Resource: "*"` or approach a hard limit, document why
7. **Consider alternatives**: If hitting DynamoDB item size (400 KB), store large payloads in S3 with a pointer in DynamoDB