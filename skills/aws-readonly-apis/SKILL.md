---
name: aws-readonly-apis
description: Comprehensive catalog of safe read-only AWS CLI commands organized by service. Use this to verify which API calls are safe for read-only exploration and to find the right commands for discovering AWS resources.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: aws-reference
  safety: read-only
---

# AWS Read-Only API Reference

This skill catalogs safe read-only AWS CLI commands for account exploration. All commands listed here only **read** data -- they never create, modify, or delete resources.

---

## Safe Read-Only Command Prefixes

These AWS CLI action prefixes are universally safe across all services:

| Prefix | Example | Safe? |
|--------|---------|-------|
| `describe-*` | `aws ec2 describe-instances` | Always safe |
| `list-*` | `aws iam list-users` | Always safe |
| `get-*` | `aws lambda get-function` | Almost always safe (see edge cases) |
| `batch-get-*` | `aws dynamodb batch-get-item` | Safe (reads multiple items) |
| `head-*` | `aws s3api head-object` | Safe (metadata only) |
| `search-*` | `aws resource-groups search-resources` | Safe |
| `lookup-*` | `aws route53 list-hosted-zones` | Safe |
| `check-*` | `aws route53 get-health-check-status` | Safe |
| `validate-*` | `aws cloudformation validate-template` | Safe |
| `decode-*` | `aws sts decode-authorization-message` | Safe |
| `simulate-*` | `aws iam simulate-principal-policy` | Safe (dry-run) |
| `estimate-*` | `aws cloudformation estimate-template-cost` | Safe |
| `calculate-*` | `aws pricing calculate-*` | Safe |

---

## DANGEROUS Command Prefixes -- NEVER USE

These prefixes modify state and must NEVER be used:

| Prefix | Risk |
|--------|------|
| `create-*` | Creates new resources |
| `delete-*`, `remove-*` | Destroys resources (often irreversible) |
| `update-*`, `modify-*` | Changes configuration |
| `put-*` | Writes/overwrites data or config |
| `start-*` | Starts resources (cost implications) |
| `stop-*` | Stops running resources |
| `terminate-*` | Destroys instances |
| `reboot-*` | Restarts resources |
| `invoke-*` | Executes code (Lambda) |
| `run-*` | Runs tasks/commands |
| `send-*` | Sends messages |
| `publish-*` | Publishes to topics |
| `attach-*`, `detach-*` | Modifies resource relationships |
| `associate-*`, `disassociate-*` | Modifies resource links |
| `enable-*`, `disable-*` | Toggles features |
| `register-*`, `deregister-*` | Registers/removes targets |
| `import-*`, `export-*` | Data transfer operations |
| `tag-*`, `untag-*` | Modifies resource tags |
| `assume-role` | Creates temporary credentials |
| `s3 cp`, `s3 mv`, `s3 rm`, `s3 sync` | S3 write operations |

---

## Edge Cases and Warnings

### Commands Named "get" That Have Side Effects
| Command | Risk | Recommendation |
|---------|------|----------------|
| `aws s3 get-object` | Downloads file to local disk | Use `head-object` for metadata instead |
| `aws s3api get-object` | Same -- downloads data | Use `head-object` |
| `aws logs get-log-events` | Safe but can be very expensive at scale | Use `--limit` parameter |
| `aws logs get-query-results` | Safe but requires a prior `start-query` | Avoid (start-query is a write) |

### Commands That Look Read-Only But Aren't
| Command | Actual Behavior |
|---------|-----------------|
| `aws logs start-query` | Creates a CloudWatch Logs Insights query (write) |
| `aws sts assume-role` | Creates temporary security credentials (write) |
| `aws sts get-session-token` | Creates temporary credentials (write) |
| `aws s3 presign` | Generates a pre-signed URL (safe itself, but URL enables writes) |
| `aws iam generate-credential-report` | Triggers report generation (write, but harmless) |
| `aws ce get-cost-forecast` | Safe but can be slow/expensive on large accounts |
| `aws config select-resource-config` | Reads only, but requires Config to be enabled |
| `aws athena start-query-execution` | Creates and runs a query (write) |

### DynamoDB Scan/Query Caution
- `scan` and `query` are read-only but consume **read capacity units**
- On large tables, a full `scan` can be very expensive and slow
- Always use `--max-items` or `--limit` to cap results
- Prefer `describe-table` for metadata over scanning data

---

## Service-by-Service Read-Only Commands

### Account & Identity
```bash
# Who am I?
aws sts get-caller-identity
aws iam get-user
aws iam list-account-aliases

# Account info
aws iam get-account-summary
aws iam get-account-authorization-details
aws organizations describe-organization
aws organizations list-accounts
aws account get-contact-information

# What region am I in?
aws configure list
aws configure get region
aws ec2 describe-regions --query 'Regions[].RegionName' --output table
aws ec2 describe-availability-zones
```

### EC2 (Compute)
```bash
# Instances
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --output table
aws ec2 describe-instance-status

# Images & Launch Templates
aws ec2 describe-images --owners self
aws ec2 describe-launch-templates

# Volumes & Snapshots
aws ec2 describe-volumes --query 'Volumes[].{ID:VolumeId,Size:Size,Type:VolumeType,State:State,AZ:AvailabilityZone}' --output table
aws ec2 describe-snapshots --owner-ids self

# Key Pairs
aws ec2 describe-key-pairs

# Auto Scaling
aws autoscaling describe-auto-scaling-groups
aws autoscaling describe-launch-configurations
aws autoscaling describe-scaling-activities
```

### VPC & Networking
```bash
# VPCs
aws ec2 describe-vpcs --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,Default:IsDefault,Name:Tags[?Key==`Name`]|[0].Value}' --output table
aws ec2 describe-subnets --query 'Subnets[].{ID:SubnetId,VPC:VpcId,AZ:AvailabilityZone,CIDR:CidrBlock,Public:MapPublicIpOnLaunch}' --output table

# Security Groups
aws ec2 describe-security-groups --query 'SecurityGroups[].{ID:GroupId,Name:GroupName,VPC:VpcId,Description:Description}' --output table

# Route Tables & Gateways
aws ec2 describe-route-tables
aws ec2 describe-internet-gateways
aws ec2 describe-nat-gateways
aws ec2 describe-vpc-endpoints

# Network ACLs
aws ec2 describe-network-acls

# Elastic IPs
aws ec2 describe-addresses

# Transit Gateway
aws ec2 describe-transit-gateways
aws ec2 describe-transit-gateway-attachments

# VPC Peering
aws ec2 describe-vpc-peering-connections

# Flow Logs
aws ec2 describe-flow-logs
```

### Load Balancing
```bash
# ALB/NLB (v2)
aws elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,Scheme:Scheme,State:State.Code,DNS:DNSName}' --output table
aws elbv2 describe-target-groups
aws elbv2 describe-listeners --load-balancer-arn <arn>
aws elbv2 describe-target-health --target-group-arn <arn>

# Classic ELB
aws elb describe-load-balancers
```

### S3
```bash
# Buckets
aws s3 ls
aws s3api list-buckets --query 'Buckets[].{Name:Name,Created:CreationDate}' --output table

# Bucket details (per bucket)
aws s3api get-bucket-location --bucket <name>
aws s3api get-bucket-versioning --bucket <name>
aws s3api get-bucket-encryption --bucket <name>
aws s3api get-bucket-policy --bucket <name>
aws s3api get-bucket-acl --bucket <name>
aws s3api get-public-access-block --bucket <name>
aws s3api get-bucket-tagging --bucket <name>
aws s3api get-bucket-logging --bucket <name>
aws s3api get-bucket-lifecycle-configuration --bucket <name>

# List objects (use --max-items to limit)
aws s3api list-objects-v2 --bucket <name> --max-items 20

# Object metadata (no download)
aws s3api head-object --bucket <name> --key <key>
```

### Lambda
```bash
aws lambda list-functions --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize,Timeout:Timeout,LastModified:LastModified}' --output table
aws lambda get-function --function-name <name>
aws lambda get-function-configuration --function-name <name>
aws lambda list-event-source-mappings
aws lambda list-layers
aws lambda get-policy --function-name <name>
```

### IAM
```bash
# Users
aws iam list-users --query 'Users[].{Name:UserName,Created:CreateDate,LastUsed:PasswordLastUsed}' --output table
aws iam list-user-policies --user-name <name>
aws iam list-attached-user-policies --user-name <name>
aws iam list-access-keys --user-name <name>
aws iam get-login-profile --user-name <name>

# Roles
aws iam list-roles --query 'Roles[].{Name:RoleName,Created:CreateDate,Path:Path}' --output table
aws iam get-role --role-name <name>
aws iam list-role-policies --role-name <name>
aws iam list-attached-role-policies --role-name <name>

# Policies
aws iam list-policies --scope Local --query 'Policies[].{Name:PolicyName,ARN:Arn,Attached:AttachmentCount}' --output table
aws iam get-policy --policy-arn <arn>
aws iam get-policy-version --policy-arn <arn> --version-id <v>

# Groups
aws iam list-groups
aws iam list-group-policies --group-name <name>

# MFA & Password Policy
aws iam list-mfa-devices
aws iam list-virtual-mfa-devices
aws iam get-account-password-policy

# Access Analyzer
aws accessanalyzer list-analyzers
aws accessanalyzer list-findings --analyzer-arn <arn>
```

### RDS
```bash
aws rds describe-db-instances --query 'DBInstances[].{ID:DBInstanceIdentifier,Engine:Engine,Class:DBInstanceClass,Status:DBInstanceStatus,Storage:AllocatedStorage}' --output table
aws rds describe-db-clusters
aws rds describe-db-subnet-groups
aws rds describe-db-parameter-groups
aws rds describe-db-snapshots --snapshot-type manual
aws rds describe-event-subscriptions
```

### DynamoDB
```bash
aws dynamodb list-tables
aws dynamodb describe-table --table-name <name>
aws dynamodb describe-continuous-backups --table-name <name>
aws dynamodb list-global-tables
aws dynamodb list-backups

# Read items (use --max-items to limit cost)
aws dynamodb scan --table-name <name> --max-items 5 --select COUNT
```

### ECS & EKS
```bash
# ECS
aws ecs list-clusters
aws ecs describe-clusters --clusters <name>
aws ecs list-services --cluster <name>
aws ecs describe-services --cluster <name> --services <name>
aws ecs list-tasks --cluster <name>
aws ecs describe-tasks --cluster <name> --tasks <arn>
aws ecs list-task-definitions
aws ecs describe-task-definition --task-definition <name>

# EKS
aws eks list-clusters
aws eks describe-cluster --name <name>
aws eks list-nodegroups --cluster-name <name>
aws eks describe-nodegroup --cluster-name <name> --nodegroup-name <name>
aws eks list-fargate-profiles --cluster-name <name>
```

### CloudFormation
```bash
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE
aws cloudformation describe-stacks
aws cloudformation describe-stack-resources --stack-name <name>
aws cloudformation get-template --stack-name <name>
aws cloudformation list-exports
aws cloudformation list-imports --export-name <name>
aws cloudformation describe-stack-events --stack-name <name>
```

### Route 53
```bash
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id <id>
aws route53 get-hosted-zone --id <id>
aws route53 list-health-checks
aws route53 get-health-check-status --health-check-id <id>
```

### CloudWatch
```bash
aws cloudwatch describe-alarms --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}' --output table
aws cloudwatch list-dashboards
aws cloudwatch list-metrics --namespace <ns>
aws cloudwatch get-metric-statistics --namespace <ns> --metric-name <name> --start-time <t> --end-time <t> --period 300 --statistics Average

# Logs
aws logs describe-log-groups --query 'logGroups[].{Name:logGroupName,Stored:storedBytes,Retention:retentionInDays}' --output table
aws logs describe-log-streams --log-group-name <name> --order-by LastEventTime --descending --max-items 10
aws logs get-log-events --log-group-name <name> --log-stream-name <stream> --limit 20
```

### CloudTrail
```bash
aws cloudtrail describe-trails
aws cloudtrail get-trail-status --name <name>
aws cloudtrail lookup-events --max-items 20
```

### SNS & SQS
```bash
# SNS
aws sns list-topics
aws sns list-subscriptions
aws sns get-topic-attributes --topic-arn <arn>

# SQS
aws sqs list-queues
aws sqs get-queue-attributes --queue-url <url> --attribute-names All
```

### Secrets Manager & KMS
```bash
# Secrets (metadata only -- never get-secret-value!)
aws secretsmanager list-secrets --query 'SecretList[].{Name:Name,LastChanged:LastChangedDate,LastAccessed:LastAccessedDate}' --output table
aws secretsmanager describe-secret --secret-id <name>
# WARNING: Do NOT use get-secret-value -- it retrieves the actual secret!

# KMS
aws kms list-keys
aws kms describe-key --key-id <id>
aws kms list-aliases
aws kms get-key-policy --key-id <id> --policy-name default
aws kms get-key-rotation-status --key-id <id>
```

### ACM (Certificates)
```bash
aws acm list-certificates --query 'CertificateSummaryList[].{Domain:DomainName,ARN:CertificateArn,Status:Status}' --output table
aws acm describe-certificate --certificate-arn <arn>
```

### EventBridge
```bash
aws events list-rules
aws events describe-rule --name <name>
aws events list-targets-by-rule --rule <name>
aws events list-event-buses
```

### Step Functions
```bash
aws stepfunctions list-state-machines
aws stepfunctions describe-state-machine --state-machine-arn <arn>
aws stepfunctions list-executions --state-machine-arn <arn> --max-results 10
```

### API Gateway
```bash
# REST APIs (v1)
aws apigateway get-rest-apis
aws apigateway get-resources --rest-api-id <id>
aws apigateway get-stages --rest-api-id <id>

# HTTP/WebSocket APIs (v2)
aws apigatewayv2 get-apis
aws apigatewayv2 get-routes --api-id <id>
aws apigatewayv2 get-stages --api-id <id>
```

### CloudFront
```bash
aws cloudfront list-distributions --query 'DistributionList.Items[].{ID:Id,Domain:DomainName,Status:Status,Origins:Origins.Items[0].DomainName}' --output table
aws cloudfront get-distribution --id <id>
aws cloudfront list-invalidations --distribution-id <id>
```

### ElastiCache
```bash
aws elasticache describe-cache-clusters
aws elasticache describe-replication-groups
aws elasticache describe-cache-subnet-groups
```

### Redshift
```bash
aws redshift describe-clusters
aws redshift describe-cluster-subnet-groups
```

### Security Hub & GuardDuty
```bash
# Security Hub
aws securityhub get-findings --max-items 20
aws securityhub describe-hub
aws securityhub get-enabled-standards

# GuardDuty
aws guardduty list-detectors
aws guardduty get-detector --detector-id <id>
aws guardduty list-findings --detector-id <id> --max-results 20
aws guardduty get-findings --detector-id <id> --finding-ids <ids>
```

### AWS Config
```bash
aws configservice describe-config-rules
aws configservice describe-compliance-by-config-rule
aws configservice describe-configuration-recorders
aws configservice get-compliance-summary-by-resource-type
aws configservice list-discovered-resources --resource-type AWS::EC2::Instance
```

### Cost Explorer
```bash
# Monthly costs
aws ce get-cost-and-usage --time-period Start=2025-01-01,End=2025-02-01 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE

# Daily costs
aws ce get-cost-and-usage --time-period Start=2025-01-01,End=2025-01-31 --granularity DAILY --metrics UnblendedCost

# Forecast
aws ce get-cost-forecast --time-period Start=2025-02-01,End=2025-03-01 --metric UNBLENDED_COST --granularity MONTHLY

# Budgets
aws budgets describe-budgets --account-id <id>

# Reservations & Savings Plans
aws ce get-reservation-utilization --time-period Start=2025-01-01,End=2025-02-01
aws ce get-savings-plans-utilization --time-period Start=2025-01-01,End=2025-02-01
```

### SSM (Systems Manager)
```bash
aws ssm describe-instance-information
aws ssm list-commands --max-results 20
aws ssm describe-parameters
aws ssm get-parameter --name <name>  # Reads parameter value (safe for non-SecureString)
aws ssm get-parameters-by-path --path /my/path --recursive
```

### ECR (Container Registry)
```bash
aws ecr describe-repositories
aws ecr list-images --repository-name <name>
aws ecr describe-images --repository-name <name>
aws ecr get-repository-policy --repository-name <name>
```

### Cognito
```bash
aws cognito-idp list-user-pools --max-results 20
aws cognito-idp describe-user-pool --user-pool-id <id>
aws cognito-idp list-user-pool-clients --user-pool-id <id>
aws cognito-identity list-identity-pools --max-results 20
```

### AppSync
```bash
aws appsync list-graphql-apis
aws appsync get-graphql-api --api-id <id>
aws appsync list-data-sources --api-id <id>
aws appsync list-resolvers --api-id <id> --type-name Query
```

### Kinesis
```bash
aws kinesis list-streams
aws kinesis describe-stream --stream-name <name>
aws kinesis describe-stream-summary --stream-name <name>
aws firehose list-delivery-streams
aws firehose describe-delivery-stream --delivery-stream-name <name>
```

### WAF
```bash
aws wafv2 list-web-acls --scope REGIONAL
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1
aws wafv2 get-web-acl --name <name> --scope REGIONAL --id <id>
```

---

## Cross-Region Scanning Pattern

To scan resources across all regions:
```bash
for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo "=== $region ==="
  aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name}' --output table 2>/dev/null
done
```

**Note**: This is slow and makes many API calls. Only use when the user explicitly requests cross-region scanning. Always check the current region first.

---

## Resource Tagging Discovery

```bash
# Find all tagged resources
aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].{ARN:ResourceARN,Tags:Tags}' --output json

# Find resources by tag
aws resourcegroupstaggingapi get-resources --tag-filters Key=Environment,Values=production
```

---

## Output Formatting Tips

```bash
# JMESPath --query for focused output
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]' --output table

# jq for complex transforms
aws ec2 describe-instances | jq '.Reservations[].Instances[] | {id: .InstanceId, type: .InstanceType, state: .State.Name}'

# Count resources
aws ec2 describe-instances --query 'length(Reservations[].Instances[])'

# Sort by date
aws s3api list-objects-v2 --bucket <name> --query 'sort_by(Contents, &LastModified)[-5:].[Key,LastModified,Size]' --output table
```
