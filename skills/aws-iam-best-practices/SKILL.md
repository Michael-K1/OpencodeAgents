---
description: >
  Comprehensive IAM best practices reference. Covers least-privilege policy
  patterns, common anti-patterns, condition keys, service-specific policy
  templates, trust policies, permission boundaries, SCPs, and cross-account
  access patterns. Load this skill when crafting, reviewing, or auditing
  IAM policies.
---

# AWS IAM Best Practices Reference

## Foundational Principles

### 1. Least Privilege
Every IAM policy should grant **only the permissions required** to perform the intended task — nothing more.

**Checklist before writing a policy:**
- What specific API actions are needed? (not `s3:*`, but `s3:GetObject`, `s3:PutObject`)
- What specific resources? (not `*`, but `arn:aws:s3:::my-bucket/*`)
- Are there conditions that can further restrict? (source IP, VPC, time, tags)
- Is this temporary or permanent? (use STS for temporary)

### 2. Defense in Depth
Layer multiple controls:
```
SCPs (Organization) → Permission Boundaries → Identity Policies → Resource Policies → VPC Endpoints
```

### 3. Separation of Duties
- Different roles for different functions (deploy vs. operate vs. audit)
- Break-glass procedures for emergency access
- No single role should have both read and delete on critical data

---

## Policy Structure Reference

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescriptiveStatementId",
      "Effect": "Allow",
      "Action": [
        "service:ActionName"
      ],
      "Resource": [
        "arn:aws:service:region:account:resource"
      ],
      "Condition": {
        "ConditionOperator": {
          "ConditionKey": "ConditionValue"
        }
      }
    }
  ]
}
```

### Version
Always use `"2012-10-17"` — the only current policy language version.

### Effect
- `Allow` — explicitly grants access
- `Deny` — explicitly denies access (takes precedence over Allow)

### Action Wildcards
```json
"s3:Get*"           // All S3 Get actions (GetObject, GetBucketPolicy, etc.)
"s3:*Object"        // All S3 Object actions
"s3:*"              // ALL S3 actions — AVOID
"*"                 // ALL actions on ALL services — NEVER USE
```

### Resource ARN Patterns
```
arn:aws:service:region:account-id:resource-type/resource-id
arn:aws:s3:::my-bucket                    // Bucket itself
arn:aws:s3:::my-bucket/*                  // Objects in bucket
arn:aws:s3:::my-bucket/prefix/*           // Objects under prefix
arn:aws:dynamodb:eu-central-1:123456789012:table/MyTable
arn:aws:lambda:*:123456789012:function:my-func-*   // Cross-region wildcard
arn:aws:ecs:eu-central-1:123456789012:service/my-cluster/my-service*
```

---

## Condition Keys Reference

### Global Condition Keys (work with all services)

```json
// Source IP restriction
"Condition": {
  "IpAddress": {
    "aws:SourceIp": ["10.0.0.0/8", "192.168.0.0/16"]
  }
}

// VPC endpoint restriction
"Condition": {
  "StringEquals": {
    "aws:SourceVpce": "vpce-1234567890abcdef0"
  }
}

// VPC restriction
"Condition": {
  "StringEquals": {
    "aws:SourceVpc": "vpc-1234567890abcdef0"
  }
}

// Organization restriction
"Condition": {
  "StringEquals": {
    "aws:PrincipalOrgID": "o-xxxxxxxxxxxxx"
  }
}

// MFA required
"Condition": {
  "Bool": {
    "aws:MultiFactorAuthPresent": "true"
  }
}

// Time-based restriction
"Condition": {
  "DateGreaterThan": {"aws:CurrentTime": "2025-01-01T00:00:00Z"},
  "DateLessThan": {"aws:CurrentTime": "2025-12-31T23:59:59Z"}
}

// Tag-based access control (ABAC)
"Condition": {
  "StringEquals": {
    "aws:ResourceTag/Environment": "production",
    "aws:PrincipalTag/Department": "engineering"
  }
}

// Require encryption in transit
"Condition": {
  "Bool": {
    "aws:SecureTransport": "true"
  }
}

// Require specific encryption
"Condition": {
  "StringEquals": {
    "s3:x-amz-server-side-encryption": "aws:kms",
    "s3:x-amz-server-side-encryption-aws-kms-key-id": "arn:aws:kms:..."
  }
}

// Request tag conditions (enforce tagging on creation)
"Condition": {
  "StringEquals": {
    "aws:RequestTag/Environment": ["dev", "stg", "prd"]
  },
  "ForAllValues:StringEquals": {
    "aws:TagKeys": ["Environment", "Owner", "Service"]
  }
}

// Caller account restriction
"Condition": {
  "StringEquals": {
    "aws:CalledVia": ["cloudformation.amazonaws.com"]
  }
}
```

### Service-Specific Condition Keys

```json
// S3 — restrict to specific prefix
"Condition": {
  "StringLike": {
    "s3:prefix": ["home/${aws:PrincipalTag/username}/*"]
  }
}

// EC2 — restrict instance types
"Condition": {
  "StringEquals": {
    "ec2:InstanceType": ["t3.micro", "t3.small", "t3.medium"]
  }
}

// EC2 — restrict to specific VPC
"Condition": {
  "StringEquals": {
    "ec2:Vpc": "arn:aws:ec2:eu-central-1:123456789012:vpc/vpc-xxx"
  }
}

// RDS — restrict engine
"Condition": {
  "StringEquals": {
    "rds:DatabaseEngine": "postgres"
  }
}

// Lambda — restrict function name pattern
"Condition": {
  "StringLike": {
    "lambda:FunctionArn": "arn:aws:lambda:*:*:function:my-prefix-*"
  }
}

// STS — restrict session duration
"Condition": {
  "NumericLessThanEquals": {
    "sts:DurationSeconds": "3600"
  }
}
```

---

## Trust Policy Patterns

### ECS Task Trust
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Lambda Trust
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Cross-Account Trust (with external ID)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        }
      }
    }
  ]
}
```

### Cross-Account Trust (Organization-wide)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-xxxxxxxxxxxxx"
        }
      }
    }
  ]
}
```

### EventBridge Scheduler Trust
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "123456789012"
        }
      }
    }
  ]
}
```

### Confused Deputy Prevention
Always add `aws:SourceArn` or `aws:SourceAccount` conditions to service trust policies:
```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "s3.amazonaws.com"
  },
  "Action": "sts:AssumeRole",
  "Condition": {
    "StringEquals": {
      "aws:SourceAccount": "123456789012"
    },
    "ArnLike": {
      "aws:SourceArn": "arn:aws:s3:::my-bucket"
    }
  }
}
```

---

## Service-Specific Policy Templates

### S3 — Read Only (specific bucket + prefix)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::my-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": ["data/*"]
        }
      }
    },
    {
      "Sid": "GetObjects",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/data/*"
    }
  ]
}
```

### S3 — Write with Encryption Enforcement
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPutWithKMS",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms",
          "s3:x-amz-server-side-encryption-aws-kms-key-id": "arn:aws:kms:eu-central-1:123456789012:key/key-id"
        }
      }
    },
    {
      "Sid": "DenyUnencryptedPut",
      "Effect": "Deny",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    }
  ]
}
```

### DynamoDB — CRUD on Specific Table
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": [
        "arn:aws:dynamodb:eu-central-1:123456789012:table/MyTable",
        "arn:aws:dynamodb:eu-central-1:123456789012:table/MyTable/index/*"
      ]
    }
  ]
}
```

### SQS — Send + Receive
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SendMessages",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:eu-central-1:123456789012:my-queue"
    },
    {
      "Sid": "ReceiveMessages",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:ChangeMessageVisibility",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:eu-central-1:123456789012:my-queue"
    }
  ]
}
```

### SNS — Publish
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:eu-central-1:123456789012:my-topic"
    }
  ]
}
```

### KMS — Encrypt/Decrypt (for data key usage)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:eu-central-1:123456789012:key/key-id"
    }
  ]
}
```

### Secrets Manager — Read Secret
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:eu-central-1:123456789012:secret:my-secret-??????"
    }
  ]
}
```
Note: Secrets Manager ARNs end with 6 random characters — use `??????` or `*` suffix.

### SSM Parameter Store — Read Parameters
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:eu-central-1:123456789012:parameter/my-app/*"
    },
    {
      "Sid": "DecryptSecureStrings",
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "arn:aws:kms:eu-central-1:123456789012:key/key-id",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ssm.eu-central-1.amazonaws.com"
        }
      }
    }
  ]
}
```

### ECS Exec (for debugging containers)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
```
Note: SSM Messages actions require `Resource: "*"` — this is one of the few cases where wildcard is acceptable.

### CloudWatch Logs — Write Logs
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:eu-central-1:123456789012:log-group:/aws/ecs/my-service:*"
    }
  ]
}
```

### Lambda — Invoke Specific Function
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:eu-central-1:123456789012:function:my-function"
    }
  ]
}
```

### IoT Core — Publish/Subscribe
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:Publish",
      "Resource": "arn:aws:iot:eu-central-1:123456789012:topic/my/topic/*"
    },
    {
      "Effect": "Allow",
      "Action": "iot:Subscribe",
      "Resource": "arn:aws:iot:eu-central-1:123456789012:topicfilter/my/topic/*"
    },
    {
      "Effect": "Allow",
      "Action": "iot:Connect",
      "Resource": "arn:aws:iot:eu-central-1:123456789012:client/${iot:ClientId}"
    }
  ]
}
```

---

## Permission Boundaries

Permission boundaries set the **maximum permissions** a role or user can have, regardless of what identity policies grant:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowedServices",
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "sqs:*",
        "sns:*",
        "logs:*",
        "cloudwatch:*",
        "xray:*",
        "ssm:GetParameter*",
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyIAMEscalation",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:PutRolePermissionsBoundary",
        "iam:DeleteRolePermissionsBoundary"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyOrganizationChanges",
      "Effect": "Deny",
      "Action": "organizations:*",
      "Resource": "*"
    }
  ]
}
```

Apply to a role:
```json
// Terraform
resource "aws_iam_role" "app_role" {
  name                 = "app-role"
  permissions_boundary = aws_iam_policy.boundary.arn
  assume_role_policy   = data.aws_iam_policy_document.trust.json
}
```

---

## Service Control Policies (SCPs)

SCPs restrict what **all principals in an account** can do. They don't grant permissions — they set guardrails.

### Deny Region Outside Allowed List
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideAllowedRegions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["eu-central-1", "us-east-1"]
        },
        "ArnNotLike": {
          "aws:PrincipalARN": [
            "arn:aws:iam::*:role/OrganizationAdmin"
          ]
        }
      }
    }
  ]
}
```

### Deny Root User Actions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootUserActions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
```

### Require Encryption on S3
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedS3Uploads",
      "Effect": "Deny",
      "Action": "s3:PutObject",
      "Resource": "*",
      "Condition": {
        "StringNotEqualsIfExists": {
          "s3:x-amz-server-side-encryption": ["aws:kms", "AES256"]
        }
      }
    }
  ]
}
```

### Prevent Leaving Organization
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    }
  ]
}
```

---

## Common Anti-Patterns (AVOID)

### 1. Wildcard Everything
```json
// BAD
{"Effect": "Allow", "Action": "*", "Resource": "*"}

// GOOD — specify exact actions and resources
{"Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::bucket/prefix/*"}
```

### 2. Overly Broad S3 Access
```json
// BAD — grants access to ALL S3 actions on ALL buckets
{"Effect": "Allow", "Action": "s3:*", "Resource": "*"}

// GOOD — specific actions on specific bucket
{"Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject"], "Resource": "arn:aws:s3:::my-bucket/*"}
```

### 3. Missing Resource Constraint on Bucket vs Objects
```json
// BAD — ListBucket on objects ARN doesn't work
{"Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::my-bucket/*"}

// GOOD — ListBucket needs bucket ARN, GetObject needs objects ARN
{"Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::my-bucket"}
{"Effect": "Allow", "Action": "s3:GetObject",  "Resource": "arn:aws:s3:::my-bucket/*"}
```

### 4. Long-Lived Access Keys for Humans
```
// BAD — IAM user with access keys for human developers
aws_iam_user + aws_iam_access_key

// GOOD — Use SSO/federation for human access, access keys only for service accounts
aws sso login --profile my-profile
```

### 5. Shared Roles Across Services
```
// BAD — one role for all ECS services
resource "aws_iam_role" "ecs_role" { ... }  // shared by 15 services

// GOOD — per-service roles with specific permissions
resource "aws_iam_role" "ecs_task_role" {
  for_each = var.container_map
  name     = "${local.base_name}${each.key}TaskRole"
}
```

### 6. Missing Deny Statements for Critical Actions
```json
// GOOD — explicit deny for critical operations even if no Allow exists
// (defense against future policy additions)
{
  "Sid": "DenyDeleteOnProductionDB",
  "Effect": "Deny",
  "Action": [
    "rds:DeleteDBInstance",
    "rds:DeleteDBCluster"
  ],
  "Resource": "arn:aws:rds:*:*:db:*prd*"
}
```

### 7. PassRole Without Restriction
```json
// BAD — can pass any role
{"Effect": "Allow", "Action": "iam:PassRole", "Resource": "*"}

// GOOD — restrict which roles can be passed and to which service
{
  "Effect": "Allow",
  "Action": "iam:PassRole",
  "Resource": "arn:aws:iam::123456789012:role/my-ecs-task-role",
  "Condition": {
    "StringEquals": {
      "iam:PassedToService": "ecs-tasks.amazonaws.com"
    }
  }
}
```

---

## Actions That Require Resource: "*"

Some AWS API actions do **not support resource-level permissions**. These are the only cases where `"Resource": "*"` is acceptable:

| Service | Actions |
|---|---|
| **IAM** | `iam:CreateServiceLinkedRole`, `iam:ListRoles`, `iam:ListPolicies` |
| **ECS** | `ecs:DescribeTaskDefinition`, `ecs:RegisterTaskDefinition`, `ecs:ListClusters` |
| **EC2** | `ec2:DescribeInstances`, `ec2:DescribeSecurityGroups`, `ec2:DescribeVpcs` (most Describe* actions) |
| **SSM** | `ssm:DescribeParameters`, `ssmmessages:*` (for ECS Exec) |
| **CloudWatch** | `cloudwatch:PutMetricData`, `cloudwatch:GetMetricData`, `logs:CreateLogGroup` |
| **KMS** | `kms:CreateGrant` (with `kms:ViaService` condition recommended) |
| **STS** | `sts:GetCallerIdentity`, `sts:DecodeAuthorizationMessage` |
| **ECR** | `ecr:GetAuthorizationToken` |
| **S3** | `s3:ListAllMyBuckets`, `s3:GetBucketLocation` |

**Always document why `"Resource": "*"` is necessary** with a comment in the policy.

---

## Policy Size Limits

| Policy Type | Max Size |
|---|---|
| Managed policy (per version) | 6,144 characters |
| Inline policy (per role) | 10,240 characters |
| Trust policy | 2,048 characters |
| SCP | 5,120 characters |
| Permission boundary | Same as managed policy (6,144) |
| Max managed policies per role | 10 (default, can be increased to 20) |
| Max inline policies per role | No hard limit, but total inline < 10,240 chars |

**Tip**: If hitting size limits, split into multiple managed policies or use wildcard patterns strategically on the resource ARN (not actions).
