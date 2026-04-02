# OpencodeAgents

Version-controlled [OpenCode](https://opencode.ai) agent and skill configurations stored as Markdown files with YAML frontmatter. No application code -- just declarative configuration that you can review, diff, and collaborate on with standard Git workflows.

## Overview

OpenCode supports custom agents (specialized AI assistants) and skills (reference documents agents can load on demand). This repository versions those configurations so they are:

- **Reviewable** -- every change is a Markdown diff
- **Portable** -- clone the repo and copy files into `~/.config/opencode/` on any machine
- **Collaborative** -- multiple developers can propose new agents or skills via pull requests

The repository currently contains an ecosystem of **AWS-focused agents** that work together in a delegation hierarchy, plus **reference skills** that agents load when they need domain-specific knowledge.

## Quick Start

### Using these agents and skills

1. Clone the repository:

```bash
git clone https://github.com/Michael-K1/OpencodeAgents.git
```

2. Copy agents and skills into your OpenCode config directory:

```bash
cp -r agents/* ~/.config/opencode/agents/
cp -r skills/* ~/.config/opencode/skills/
```

3. Restart OpenCode. The agents will appear in your agent list and skills will be available for loading.

### Prerequisites

- [OpenCode](https://opencode.ai) installed and configured
- [Bun](https://bun.sh) (optional, only needed if adding TypeScript tools/plugins in the future)

```bash
bun install
```

## Repository Structure

```
OpencodeAgents/
├── AGENTS.md                          # Detailed conventions, file formats, and contribution rules
├── README.md                          # This file
├── package.json                       # Declares @opencode-ai/plugin dependency
├── .gitignore
├── agents/                            # Agent definitions (one file per agent)
│   ├── opencode-expert.md
│   ├── aws-architect.md
│   ├── aws-developer.md
│   ├── aws-security-auditor.md
│   ├── aws-cost-analyst.md
│   ├── iac-cfn.md
│   ├── iac-sam.md
│   ├── iac-sls-v3.md
│   └── iac-sls-v4.md
└── skills/                            # Skill reference documents
    ├── opencode-agents/
    │   └── SKILL.md
    ├── aws-iam-best-practices/
    │   └── SKILL.md
    └── aws-service-quotas/
        └── SKILL.md
```

## Agents

Each agent is a Markdown file in `agents/` with YAML frontmatter defining its behavior, model, permissions, and system prompt.

### Current Agents

| Agent | Description |
|---|---|
| **opencode-expert** | Designs and builds OpenCode agents, skills, commands, tools, and plugins |
| **aws-architect** | Strategic AWS architecture design, service selection, trade-off analysis, and HA/DR planning |
| **aws-developer** | Implementation bridge between architecture decisions and IaC code; delegates to IaC specialists |
| **aws-security-auditor** | Read-only security posture assessments using Security Hub, GuardDuty, IAM Access Analyzer, and more |
| **aws-cost-analyst** | Cost breakdowns, optimization recommendations, savings plan analysis, and forecasting |
| **iac-cfn** | Writes, reviews, and debugs CloudFormation templates (YAML/JSON) |
| **iac-sam** | AWS SAM templates, sam-cli commands, local testing, and CI/CD pipelines |
| **iac-sls-v3** | Serverless Framework v3.x configuration, plugins, and deployment |
| **iac-sls-v4** | Serverless Framework v4.x with ESM support, composable configs, and updated IAM model |

### Agent Delegation Hierarchy

The AWS agents form a five-tier delegation DAG where higher-tier agents invoke lower-tier specialists. Cross-tier shortcuts exist for latency reduction. The full graph has **62 edges across 18 agents with 0 cycles**.

```text
Tier 4  aws-architect ──→ aws-developer, aws-cost-analyst, aws-security-auditor, aws-explorer, aws-librarian
Tier 3  aws-developer ──→ iac-terraform, iac-cfn, iac-sam, iac-sls-v3/v4, lambda-*, aws-explorer, aws-librarian
Tier 2  IaC specialists + opencode-expert ──→ lambda-*, aws-librarian, explore
Tier 1  Domain specialists ──→ aws-explorer, aws-librarian, explore
Tier 0  aws-explorer, aws-librarian (leaf nodes -- no delegation)
```

See [AGENT_DELEGATION_SCHEMA.md](./AGENT_DELEGATION_SCHEMA.md) for the complete DAG with every delegation edge, the edge summary table, and context-passing best practices.

## Skills

Skills are reference documents that agents load on demand for domain-specific knowledge. Each skill lives in its own directory under `skills/` with a `SKILL.md` file.

### Current Skills

| Skill | Description |
|---|---|
| **opencode-agents** | Comprehensive reference for creating and configuring OpenCode agents, skills, commands, tools, and plugins |
| **aws-iam-best-practices** | IAM least-privilege patterns, condition keys, trust policies, permission boundaries, SCPs, anti-patterns, and policy templates |
| **aws-service-quotas** | AWS service quotas and limits for compute, networking, storage, databases, messaging, security, API Gateway, and CloudFormation |

## Adding New Agents and Skills

This section provides a quick overview. For detailed file format specifications, naming rules, YAML style, and Markdown conventions, see [AGENTS.md](./AGENTS.md).

### Adding an Agent

1. Create `agents/<agent-name>.md` using kebab-case naming
2. Add YAML frontmatter with at least a `description` field (required for discoverability)
3. Configure `mode`, `model`, `temperature`, `color`, and `permission` as needed
4. Write the system prompt in the Markdown body
5. Verify the frontmatter parses correctly as YAML

### Adding a Skill

1. Create a directory `skills/<skill-name>/` (must match the `name` in frontmatter)
2. Create `skills/<skill-name>/SKILL.md` (uppercase filename, always `SKILL.md`)
3. Add frontmatter with `name` and `description`
4. Write reference content in the Markdown body

### Skill Name Rules

Skill directory names must:
- Be 1-64 characters
- Use only lowercase alphanumeric characters and single hyphens
- Not start or end with a hyphen
- Match: `^[a-z0-9]+(-[a-z0-9]+)*$`

## Contributing

### Commit Conventions

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) with an `[Agent]` tag for AI-authored commits.

Format: `<type>(<scope>): <description> [Agent]`

| Type | When to use |
|---|---|
| `feat` | New agent, skill, command, tool, or plugin |
| `fix` | Correct an error in configuration or content |
| `docs` | Documentation-only changes |
| `refactor` | Restructure without changing behavior |
| `chore` | Maintenance (dependency updates, .gitignore, etc.) |

Scopes: `agent`, `skill`, `command`, `tool`, `plugin`, or omit for repo-wide changes.

Examples:

```
feat(agent): add code-reviewer agent [Agent]
fix(skill): correct YAML frontmatter in opencode-agents [Agent]
docs: update README with new agent table [Agent]
```

### Validation

There are no build, lint, or test commands. Validate changes by:

- Ensuring YAML frontmatter parses correctly between `---` delimiters
- Checking that all required fields are present (`description` for agents, `name` + `description` for skills)
- Verifying skill directory names match the `name` field in frontmatter
- Reviewing Markdown structure follows the conventions in [AGENTS.md](./AGENTS.md)

## Resources

- [OpenCode Documentation](https://opencode.ai/docs) -- official docs for agents, skills, commands, and plugins
- [AGENTS.md](./AGENTS.md) -- detailed repository conventions, file formats, naming rules, and style guides
- [Conventional Commits](https://www.conventionalcommits.org/) -- commit message specification used in this repo
