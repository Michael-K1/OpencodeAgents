# Agent Delegation Schema

This document describes the delegation flow and orchestration relationships between OpenCode agents in the AWS ecosystem.

## Architecture Overview

```
                              aws-architect (Strategic Planner)
                                      │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            aws-developer         aws-cost-analyst    aws-security-auditor
         (Implementation)         (Cost Analysis)     (Security Review)
                    │                   │                   │
        ┌───────────┼───────────┐       │                   │
        │           │           │       │                   │
        ▼           ▼           ▼       │                   │
  terraform-expert serverless-* sam-expert  │                   │
  cfn-expert                    │                   │
        │           │           │       │                   │
        └───────────┼───────────┴───────┼───────────────────┘
                    │                   │
                    ▼                   ▼
            aws-librarian (Documentation Specialist)
```

## Delegation Flow Details

### Level 1: Strategic Planning
**aws-architect**
- Role: AWS Solutions Architect
- Responsibility: Strategic architecture design and planning
- Analysis: Account discovery, infrastructure assessment, architecture recommendations
- Delegations:
  - → **aws-developer**: For implementation planning
  - → **aws-cost-analyst**: For cost analysis and optimization
  - → **aws-security-auditor**: For security posture review
  - → **aws-librarian**: For AWS documentation lookups (service guides, quotas, pricing)

### Level 2: Specialized Domains

#### Implementation Domain: **aws-developer**
- Role: Implementation-focused engineer
- Responsibility: Bridge architecture decisions to infrastructure code
- Expertise: AWS APIs, SDKs, IAM policies, service configurations, cross-service patterns
- Delegations:
  - → **terraform-expert**: For Terraform HCL infrastructure code
  - → **serverless-v3-expert**: For Serverless Framework v3.x projects
  - → **serverless-v4-expert**: For Serverless Framework v4.x projects
  - → **sam-expert**: For AWS SAM (Serverless Application Model) projects
  - → **cfn-expert**: For raw CloudFormation templates (YAML/JSON)
  - → **aws-librarian**: For AWS documentation and API reference lookups

#### Cost Domain: **aws-cost-analyst**
- Role: AWS Cost Analyst
- Responsibility: Cost analysis, optimization, financial planning
- Expertise: Cost Explorer, Reserved Instances, Savings Plans, right-sizing, waste detection
- Delegations:
  - → **aws-librarian**: For pricing information and service quotas

#### Security Domain: **aws-security-auditor**
- Role: AWS Security Auditor
- Responsibility: Security posture assessment and compliance review
- Expertise: IAM policy analysis, Security Hub, GuardDuty, network security, encryption audit
- Delegations:
  - → **aws-librarian**: For security best practices and compliance documentation

### Level 3: Infrastructure-as-Code Specialists

These agents implement infrastructure based on briefs from **aws-developer**:

| Agent | Specialization | Input | Output |
|-------|----------------|-------|--------|
| **terraform-expert** | Terraform HCL | Implementation brief | .tf files, deployment code |
| **serverless-v3-expert** | Serverless v3 YAML | Implementation brief | serverless.yml (v3.x) |
| **serverless-v4-expert** | Serverless v4 YAML | Implementation brief | serverless.yml (v4.x) |
| **sam-expert** | AWS SAM template | Implementation brief | template.yaml |
| **cfn-expert** | CloudFormation | Implementation brief | CloudFormation templates |

### Level 4: Documentation & Reference

#### **aws-librarian** (Documentation Specialist)
- Role: AWS Documentation Researcher
- Responsibility: Fetch and distil official AWS documentation
- Expertise: AWS service guides, API references, quotas, pricing, best practices
- Access: Read-only webfetch (no bash, no edit)
- Serves: All other agents in the ecosystem

---

## Typical User Workflows

### Workflow 1: New AWS Architecture Design
```
User → aws-architect
  │
  ├─→ (Account discovery & analysis)
  │
  ├─→ aws-librarian (Verify service quotas & pricing)
  │
  ├─→ (Architecture recommendation)
  │
  ├─→ aws-cost-analyst (Estimate costs for options)
  │   └─→ aws-librarian (Get pricing data)
  │
  ├─→ aws-security-auditor (Review security implications)
  │   └─→ aws-librarian (Get security best practices)
  │
  └─→ (Final recommendation with trade-offs)
```

### Workflow 2: Proceed to Implementation
```
User → aws-architect (provides implementation brief)
  │
  └─→ aws-developer
      │
      ├─→ terraform-expert (if Terraform)
      │
      ├─→ serverless-v3-expert (if Serverless v3)
      │
      ├─→ serverless-v4-expert (if Serverless v4)
      │
      ├─→ sam-expert (if AWS SAM)
      │
      ├─→ cfn-expert (if CloudFormation)
      │
      └─→ aws-librarian (Verify API details, configurations)
```

### Workflow 3: Cost Analysis Deep Dive
```
User → aws-cost-analyst
  │
  ├─→ (Pull cost data, analyze spend)
  │
  ├─→ aws-librarian (Get pricing details, service limits)
  │
  └─→ (Report with optimization recommendations)
```

### Workflow 4: Security Audit
```
User → aws-security-auditor
  │
  ├─→ (Scan IAM, network, encryption)
  │
  ├─→ aws-librarian (Get security best practices, compliance standards)
  │
  └─→ (Report with risk explanations and remediation steps)
```

---

## Permission Model

### Tool Access Summary

| Agent | bash | edit | webfetch | task | skill |
|-------|------|------|----------|------|-------|
| aws-architect | read-only (allow list) | deny | allow | limited | allow |
| aws-developer | read-only (allow list) | ask | allow | IaC experts + docs | allow |
| aws-cost-analyst | read-only (allow list) | deny | allow | docs only | allow |
| aws-security-auditor | read-only (allow list) | deny | allow | docs only | allow |
| terraform-expert | read-only | ask | allow | explore | allow |
| serverless-v3-expert | read-only | ask | allow | explore | allow |
| serverless-v4-expert | read-only | ask | allow | explore | allow |
| sam-expert | read-only | ask | allow | explore | allow |
| cfn-expert | read-only | ask | allow | explore | allow |
| aws-librarian | none | deny | allow | none | allow |

**Key Principles:**
- All agents are **read-only** for AWS account inspection
- No agent modifies files without `ask` permission
- **aws-librarian** has the most restricted access (webfetch only)
- Specific bash patterns use whitelist approach: `"*": ask` (default) → specific allows/denies

---

## Orchestration Rules

### Task Tool Invocation

1. **aws-architect** invokes:
   - `aws-developer` for implementation work
   - `aws-cost-analyst` for cost analysis
   - `aws-security-auditor` for security review
   - `aws-librarian` for documentation

2. **aws-developer** invokes:
   - `terraform-expert`, `serverless-v3-expert`, `serverless-v4-expert`, `sam-expert`, `cfn-expert` for IaC
   - `aws-librarian` for API reference and configuration details

3. **aws-cost-analyst** invokes:
   - `aws-librarian` for pricing and quota information

4. **aws-security-auditor** invokes:
   - `aws-librarian` for security best practices and compliance documentation

5. **IaC Specialists** invoke:
   - `explore` agent for codebase exploration
   - No cross-invocation with other IaC specialists

---

## Context Passing Best Practices

### aws-architect → aws-developer
Pass an **Implementation Brief** containing:
- Architecture decisions and rationale
- AWS services to create/modify with specific configurations
- IAM permissions required
- Dependencies between resources
- Prerequisites and resource constraints
- Risks and considerations

### aws-developer → IaC Specialists
Pass:
- Full implementation brief from architect
- Specific resources to create (with IaC tool chosen)
- Configuration parameters and values
- Environment context (dev/stg/pre/prd)

### Any Agent → aws-librarian
Pass:
- Specific documentation need (service name, topic, limit, pricing)
- Context (region, feature, compliance framework)
- Expected format of response (summary, detailed, tabular)

---

## Future Extensions

This schema is designed to scale:
- **Additional IaC tools**: CDK Expert, Pulumi Expert, etc.
- **Cloud providers**: azure-architect, gcp-architect, multi-cloud-orchestrator
- **Domain specialists**: database-architect, kubernetes-expert, observability-specialist
- **New documentation sources**: AWS Knowledge Center, blog aggregator, user guide researcher

The delegation pattern remains consistent:
1. Strategic planning layer (architects)
2. Specialized domain layers (developers, cost analysts, security auditors)
3. Tool-specific implementation layers (IaC experts)
4. Reference/documentation layer (librarians)

---

## Related Files

- `agents/aws-architect.md` - Strategic architecture planner
- `agents/aws-developer.md` - Implementation coordinator
- `agents/aws-cost-analyst.md` - Cost analysis specialist
- `agents/aws-security-auditor.md` - Security auditor
- `agents/aws-librarian.md` - Documentation researcher
- `agents/terraform-expert.md` - Terraform expert
- `agents/serverless-v3-expert.md` - Serverless Framework v3 expert
- `agents/serverless-v4-expert.md` - Serverless Framework v4 expert
- `agents/sam-expert.md` - AWS SAM expert
- `agents/cfn-expert.md` - CloudFormation expert
