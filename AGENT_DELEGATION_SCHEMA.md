# Agent Delegation Schema

This document describes the delegation flow and orchestration relationships between OpenCode agents in the AWS ecosystem.

## Delegation DAG

The agent ecosystem forms a directed acyclic graph (DAG) with five tiers. Higher-tier agents delegate tasks to lower-tier agents. Several cross-tier shortcuts exist -- these are intentional to reduce latency when a strategist or orchestrator needs a leaf-level agent directly.

- 17 cross-tier edges exist (marked with "direct cross-tier") -- these are intentional shortcuts for latency reduction
- The graph is a valid DAG -- no cycles exist
- `explore` is a built-in OpenCode subagent, not a custom agent defined in this repository
- Every task permission map uses `"*": deny` as the first entry with specific allows after

```text
Tier 4 — Strategist
└── aws-architect
    ├──→ aws-developer          (Tier 3)
    ├──→ aws-cost-analyst       (Tier 1)
    ├──→ aws-security-auditor   (Tier 1)
    ├──→ aws-explorer           (Tier 0)  ← direct cross-tier
    ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
    └──→ explore                (built-in)

Tier 3 — Orchestrator
└── aws-developer
    ├──→ iac-terraform          (Tier 2)
    ├──→ iac-cfn                (Tier 2)
    ├──→ iac-sam                (Tier 2)
    ├──→ iac-sls-v3             (Tier 2)
    ├──→ iac-sls-v4             (Tier 2)
    ├──→ lambda-ts              (Tier 1)  ← direct cross-tier
    ├──→ lambda-python          (Tier 1)  ← direct cross-tier
    ├──→ lambda-go              (Tier 1)  ← direct cross-tier
    ├──→ aws-explorer           (Tier 0)  ← direct cross-tier
    ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
    └──→ explore                (built-in)

Tier 2 — IaC Specialists + Utility
├── iac-terraform
│   ├──→ lambda-ts              (Tier 1)
│   ├──→ lambda-python          (Tier 1)
│   ├──→ lambda-go              (Tier 1)
│   ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
│   └──→ explore                (built-in)
├── iac-cfn
│   ├──→ lambda-ts              (Tier 1)
│   ├──→ lambda-python          (Tier 1)
│   ├──→ lambda-go              (Tier 1)
│   ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
│   └──→ explore                (built-in)
├── iac-sam
│   ├──→ lambda-ts              (Tier 1)
│   ├──→ lambda-python          (Tier 1)
│   ├──→ lambda-go              (Tier 1)
│   ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
│   └──→ explore                (built-in)
├── iac-sls-v3
│   ├──→ lambda-ts              (Tier 1)
│   ├──→ lambda-python          (Tier 1)
│   ├──→ lambda-go              (Tier 1)
│   ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
│   └──→ explore                (built-in)
├── iac-sls-v4
│   ├──→ lambda-ts              (Tier 1)
│   ├──→ lambda-python          (Tier 1)
│   ├──→ lambda-go              (Tier 1)
│   ├──→ aws-librarian          (Tier 0)  ← direct cross-tier
│   └──→ explore                (built-in)
└── opencode-expert
    ├──→ ai-sensei              (Tier 1)
    └──→ explore                (built-in)

Tier 1 — Domain Specialists (delegate only to Tier 0)
├── lambda-ts
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
├── lambda-python
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
├── lambda-go
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
├── aws-cost-analyst
│   ├──→ aws-explorer           (Tier 0)
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
├── aws-security-auditor
│   ├──→ aws-explorer           (Tier 0)
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
├── incident-responder
│   ├──→ aws-explorer           (Tier 0)
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
├── ai-sensei
│   ├──→ aws-librarian          (Tier 0)
│   └──→ explore                (built-in)
└── docs-writer
    └──→ explore                (built-in)

Tier 0 — Leaf Nodes (no delegation to custom agents)
├── aws-explorer                (no Task tool targets)
└── aws-librarian               (no Task tool targets)
```

## Edge Summary

| Agent | Delegates to | Edge count |
|-------|-------------|------------|
| **aws-architect** | aws-developer, aws-cost-analyst, aws-security-auditor, aws-explorer, aws-librarian, explore | 6 |
| **aws-developer** | iac-terraform, iac-sls-v3, iac-sls-v4, iac-sam, iac-cfn, lambda-ts, lambda-python, lambda-go, aws-explorer, aws-librarian, explore | 11 |
| **iac-terraform** | lambda-ts, lambda-python, lambda-go, aws-librarian, explore | 5 |
| **iac-cfn** | lambda-ts, lambda-python, lambda-go, aws-librarian, explore | 5 |
| **iac-sam** | lambda-ts, lambda-python, lambda-go, aws-librarian, explore | 5 |
| **iac-sls-v3** | lambda-ts, lambda-python, lambda-go, aws-librarian, explore | 5 |
| **iac-sls-v4** | lambda-ts, lambda-python, lambda-go, aws-librarian, explore | 5 |
| **aws-security-auditor** | aws-explorer, aws-librarian, explore | 3 |
| **aws-cost-analyst** | aws-explorer, aws-librarian, explore | 3 |
| **incident-responder** | aws-explorer, aws-librarian, explore | 3 |
| **opencode-expert** | ai-sensei, explore | 2 |
| **ai-sensei** | aws-librarian, explore | 2 |
| **lambda-ts** | aws-librarian, explore | 2 |
| **lambda-python** | aws-librarian, explore | 2 |
| **lambda-go** | aws-librarian, explore | 2 |
| **docs-writer** | explore | 1 |
| **aws-explorer** | *(none)* | 0 |
| **aws-librarian** | *(none)* | 0 |

**Total: 62 edges across 18 agents, 0 cycles.**

## Agent Roles by Tier

### Tier 4 -- Strategist

**aws-architect**
- Role: AWS Solutions Architect
- Responsibility: Strategic architecture design and planning
- Analysis: Account discovery, infrastructure assessment, architecture recommendations
- Delegates to: aws-developer, aws-cost-analyst, aws-security-auditor, aws-explorer, aws-librarian, explore

### Tier 3 -- Orchestrator

**aws-developer**
- Role: Implementation-focused engineer
- Responsibility: Bridge architecture decisions to infrastructure code
- Expertise: AWS APIs, SDKs, IAM policies, service configurations, cross-service patterns
- Delegates to: iac-terraform, iac-cfn, iac-sam, iac-sls-v3, iac-sls-v4, lambda-ts, lambda-python, lambda-go, aws-explorer, aws-librarian, explore

### Tier 2 -- IaC Specialists + Utility

These agents implement infrastructure based on briefs from **aws-developer**:

| Agent | Specialization | Input | Output |
|-------|----------------|-------|--------|
| **iac-terraform** | Terraform HCL | Implementation brief | .tf files, deployment code |
| **iac-sls-v3** | Serverless v3 YAML | Implementation brief | serverless.yml (v3.x) |
| **iac-sls-v4** | Serverless v4 YAML | Implementation brief | serverless.yml (v4.x) |
| **iac-sam** | AWS SAM template | Implementation brief | template.yaml |
| **iac-cfn** | CloudFormation | Implementation brief | CloudFormation templates |
| **opencode-expert** | OpenCode config | Agent/skill spec | agents, skills, commands |

All IaC specialists delegate to Lambda Expert Agents when handler code is needed alongside infrastructure definitions. They also delegate directly to **aws-librarian** (cross-tier shortcut to Tier 0) and to the built-in **explore** agent.

### Tier 1 -- Domain Specialists

#### Lambda Expert Agents

These agents write Lambda handler code, business logic, and tests. They are invoked by **aws-developer** or by **IaC specialists** when a project requires both infrastructure and handler code:

| Agent | Language | Runtime | Key Libraries |
|-------|----------|---------|--------------|
| **lambda-ts** | TypeScript | Node.js 24 (ESM) | Middy v6, AWS SDK v3, Vitest |
| **lambda-python** | Python | Python 3.12+ | boto3, Lambda Powertools, pytest |
| **lambda-go** | Go | Go 1.22+ | aws-lambda-go, AWS SDK for Go v2 |

- These agents **do not write IaC** -- they focus on handler code, business logic, unit/integration tests, and shared utilities
- They delegate to **aws-librarian** for AWS API documentation lookups and to the built-in **explore** agent
- **lambda-ts** loads the `lambda-ts-conventions` skill for project-specific TypeScript patterns

#### Analysis and Advisory Agents

| Agent | Role | Delegates to |
|-------|------|-------------|
| **aws-cost-analyst** | Cost analysis, optimization, financial planning | aws-explorer, aws-librarian, explore |
| **aws-security-auditor** | Security posture assessment and compliance review | aws-explorer, aws-librarian, explore |
| **incident-responder** | Production incident diagnosis and remediation | aws-explorer, aws-librarian, explore |
| **ai-sensei** | AI/ML teaching and guidance | aws-librarian, explore |
| **docs-writer** | Technical documentation writing | explore |

### Tier 0 -- Leaf Nodes

#### **aws-librarian** (Documentation Specialist)
- Role: AWS Documentation Researcher
- Responsibility: Fetch and distil official AWS documentation
- Expertise: AWS service guides, API references, quotas, pricing, best practices
- Access: Read-only webfetch (no bash, no edit)
- Serves: All other agents in the ecosystem
- Delegates to: *(none)* -- leaf node

#### **aws-explorer** (Read-Only AWS Inspector)
- Role: Read-only AWS account explorer
- Responsibility: Safe inspection of live AWS account state
- Expertise: AWS CLI read-only commands across all services
- Access: Bash with default deny and extensive allowlist for safe read-only AWS CLI commands; no webfetch, no edit, no task delegation
- Skills: `aws-readonly-apis` only
- Invoked by: aws-architect, aws-developer, aws-cost-analyst, aws-security-auditor, incident-responder
- Delegates to: *(none)* -- leaf node

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
      ├─→ iac-terraform (if Terraform)
      │   └─→ lambda-ts / lambda-python / lambda-go (handler code)
      │
      ├─→ iac-sls-v3 (if Serverless v3)
      │   └─→ lambda-ts / lambda-python / lambda-go (handler code)
      │
      ├─→ iac-sls-v4 (if Serverless v4)
      │   └─→ lambda-ts / lambda-python / lambda-go (handler code)
      │
      ├─→ iac-sam (if AWS SAM)
      │   └─→ lambda-ts / lambda-python / lambda-go (handler code)
      │
      ├─→ iac-cfn (if CloudFormation)
      │   └─→ lambda-ts / lambda-python / lambda-go (handler code)
      │
      ├─→ lambda-ts (direct, for TypeScript handler-only tasks)
      │
      ├─→ lambda-python (direct, for Python handler-only tasks)
      │
      ├─→ lambda-go (direct, for Go handler-only tasks)
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

### Workflow 5: Lambda Handler Development (Direct)
```
User → aws-developer
  │
  ├─→ lambda-ts (TypeScript handler + business logic + tests)
  │   └─→ aws-librarian (AWS API docs, event schemas)
  │
  ├─→ lambda-python (Python handler + business logic + tests)
  │   └─→ aws-librarian (AWS API docs, event schemas)
  │
  └─→ lambda-go (Go handler + business logic + tests)
      └─→ aws-librarian (AWS API docs, event schemas)
```

### Workflow 6: Full-Stack Serverless Feature
```
User → aws-developer
  │
  ├─→ iac-sam (IaC: template.yaml with Lambda, API Gateway, DynamoDB)
  │   └─→ lambda-ts (Handler code for all functions)
  │
  └─→ (Integration testing & review)
```

---

## Permission Model

### Tool Access Summary

| Agent | bash | edit | webfetch | task | skill |
|-------|------|------|----------|------|-------|
| aws-architect | read-only (allow list) | deny | allow | limited | allow |
| aws-developer | read-only (allow list) | ask | allow | IaC + Lambda experts + docs | allow |
| aws-cost-analyst | read-only (allow list) | deny | allow | docs only | allow |
| aws-security-auditor | read-only (allow list) | deny | allow | docs only | allow |
| iac-terraform | read-only | ask | allow | explore + Lambda experts + docs | allow |
| iac-sls-v3 | read-only | ask | allow | explore + Lambda experts + docs | allow |
| iac-sls-v4 | read-only | ask | allow | explore + Lambda experts + docs | allow |
| iac-sam | read-only | ask | allow | explore + Lambda experts + docs | allow |
| iac-cfn | read-only | ask | allow | explore + Lambda experts + docs | allow |
| lambda-ts | limited (test/lint) | allow | allow | docs only | allow |
| lambda-python | limited (test/lint) | allow | allow | docs only | allow |
| lambda-go | limited (test/lint) | allow | allow | docs only | allow |
| aws-librarian | none | deny | allow | none | allow |
| aws-explorer | read-only (allow list, default deny) | deny | deny | none | restricted (aws-readonly-apis only) |

**Key Principles:**
- All agents are **read-only** for AWS account inspection
- Most agents require `ask` approval to modify files; Lambda experts have `allow` for fast code generation
- **aws-librarian** has the most restricted access (webfetch only)
- Specific bash patterns use whitelist approach: `"*": ask` (default) → specific allows/denies

---

## Orchestration Rules

### Task Tool Invocation

1. **aws-architect** (Tier 4) invokes:
   - `aws-developer` for implementation work
   - `aws-cost-analyst` for cost analysis
   - `aws-security-auditor` for security review
   - `aws-explorer` for read-only AWS account inspection (cross-tier)
   - `aws-librarian` for documentation (cross-tier)
   - `explore` for codebase exploration (built-in)

2. **aws-developer** (Tier 3) invokes:
   - `iac-terraform`, `iac-sls-v3`, `iac-sls-v4`, `iac-sam`, `iac-cfn` for IaC
   - `lambda-ts`, `lambda-python`, `lambda-go` for handler code (cross-tier)
   - `aws-explorer` for read-only AWS account inspection (cross-tier)
   - `aws-librarian` for API reference and configuration details (cross-tier)
   - `explore` for codebase exploration (built-in)

3. **IaC Specialists** (Tier 2) invoke:
   - `lambda-ts`, `lambda-python`, `lambda-go` for handler code
   - `aws-librarian` for documentation lookups (cross-tier)
   - `explore` for codebase exploration (built-in)
   - No cross-invocation with other IaC specialists

4. **opencode-expert** (Tier 2) invokes:
   - `ai-sensei` for AI/ML guidance
   - `explore` for codebase exploration (built-in)

5. **aws-cost-analyst** (Tier 1) invokes:
   - `aws-explorer` for read-only AWS account inspection
   - `aws-librarian` for pricing and quota information
   - `explore` for codebase exploration (built-in)

6. **aws-security-auditor** (Tier 1) invokes:
   - `aws-explorer` for read-only AWS account inspection
   - `aws-librarian` for security best practices and compliance documentation
   - `explore` for codebase exploration (built-in)

7. **incident-responder** (Tier 1) invokes:
   - `aws-explorer` for read-only AWS account inspection
   - `aws-librarian` for AWS documentation
   - `explore` for codebase exploration (built-in)

8. **Lambda Expert Agents** (Tier 1) invoke:
   - `aws-librarian` for AWS API documentation
   - `explore` for codebase exploration (built-in)
   - No other delegations -- they are code-production agents

9. **ai-sensei** (Tier 1) invokes:
   - `aws-librarian` for AWS documentation
   - `explore` for codebase exploration (built-in)

10. **docs-writer** (Tier 1) invokes:
    - `explore` for codebase exploration (built-in)

11. **aws-explorer** and **aws-librarian** (Tier 0):
    - No delegations -- leaf-level agents

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

### aws-developer → Lambda Expert Agents
Pass:
- **Runtime language** (TypeScript, Python, or Go)
- **Event source type** (API Gateway, SQS, S3, EventBridge Schedule, DynamoDB Streams, etc.)
- **Environment variables** the handler will receive
- **IAM permissions** available to the function
- **Business logic requirements** -- what the handler should do
- **Existing project patterns** -- if the project has established handler conventions
- **Test requirements** -- unit tests, integration tests, mock strategies

### IaC Specialists → Lambda Expert Agents
Pass:
- Same as aws-developer → Lambda Expert Agents above
- Additionally: the **IaC resource definition** for context (function config, event source mapping, etc.)
- **CodeUri / source path** where the handler should be written

### Any Agent → aws-librarian
Pass:
- Specific documentation need (service name, topic, limit, pricing)
- Context (region, feature, compliance framework)
- Expected format of response (summary, detailed, tabular)

---

## Future Extensions

This schema is designed to scale:
- **Additional IaC tools**: CDK Expert, Pulumi Expert, etc.
- **Additional Lambda runtimes**: Rust Expert, Java Expert, .NET Expert
- **Cloud providers**: azure-architect, gcp-architect, multi-cloud-orchestrator
- **Domain specialists**: database-architect, kubernetes-expert, observability-specialist
- **New documentation sources**: AWS Knowledge Center, blog aggregator, user guide researcher

The delegation pattern remains consistent:
1. Strategic planning layer (architects)
2. Specialized domain layers (developers, cost analysts, security auditors)
3. Tool-specific implementation layers (IaC experts)
4. Runtime-specific code layers (Lambda experts)
5. Reference/documentation layer (librarians)

---

## Related Files

- `agents/aws-architect.md` - Strategic architecture planner
- `agents/aws-developer.md` - Implementation coordinator
- `agents/aws-cost-analyst.md` - Cost analysis specialist
- `agents/aws-security-auditor.md` - Security auditor
- `agents/aws-librarian.md` - Documentation researcher
- `agents/aws-explorer.md` - Read-only AWS account explorer
- `agents/iac-terraform.md` - Terraform expert
- `agents/iac-sls-v3.md` - Serverless Framework v3 expert
- `agents/iac-sls-v4.md` - Serverless Framework v4 expert
- `agents/iac-sam.md` - AWS SAM expert
- `agents/iac-cfn.md` - CloudFormation expert
- `agents/lambda-ts.md` - TypeScript Lambda handler expert
- `agents/lambda-python.md` - Python Lambda handler expert
- `agents/lambda-go.md` - Go Lambda handler expert
- `agents/docs-writer.md` - Documentation writer
- `agents/opencode-expert.md` - OpenCode agent configuration expert
- `agents/ai-sensei.md` - AI/ML teaching agent
- `agents/incident-responder.md` - Production incident diagnosis
- `skills/lambda-ts-conventions/SKILL.md` - TypeScript Lambda project conventions
- `skills/lambda-delegation/SKILL.md` - Shared Lambda delegation protocol
- `skills/aws-iam-best-practices/SKILL.md` - IAM policy patterns and best practices
- `skills/aws-security-audit/SKILL.md` - Security audit checklists and compliance frameworks
- `skills/aws-service-quotas/SKILL.md` - AWS service limits reference
- `skills/aws-readonly-apis/SKILL.md` - Safe read-only AWS CLI commands
- `skills/terraform-style-guide/SKILL.md` - HashiCorp HCL style conventions
- `skills/terraform-test/SKILL.md` - Terraform native testing framework
- `skills/refactor-module/SKILL.md` - Terraform monolith-to-module refactoring
- `skills/opencode-agents/SKILL.md` - OpenCode agent creation reference
