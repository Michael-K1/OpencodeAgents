---
name: naming-conventions
description: >
  Naming conventions for OpenCode agents, skills, and commands. Provides rules
  for kebab-case identifiers, prefix-based grouping of related elements, and
  concise name construction. Load this skill when creating, renaming, or
  reviewing the names of agents, skills, or commands.
---

# Naming Conventions for Agents, Skills, and Commands

This skill defines the naming rules used across the project for agents, skills, and commands. The primary goal is **scanability** -- names should sort together in file listings and autocomplete menus when they belong to the same topic.

---

## 1. General Rules

All identifiers (agent filenames, skill directory names, command filenames) follow the same base rules:

- **Format**: `kebab-case` -- lowercase alphanumeric segments separated by single hyphens
- **Regex**: `^[a-z0-9]+(-[a-z0-9]+)*$`
- **Length**: 1--64 characters
- **No consecutive hyphens** (`--`), no leading/trailing hyphens
- **File extension**: `.md` for agents and commands; skill directories contain `SKILL.md`

---

## 2. Prefix Grouping

When **two or more elements relate to the same topic or domain**, extract a short common prefix so they sort together alphabetically.

### 2.1 How to Choose a Prefix

1. **Identify the domain** -- what topic, service, or technology ties the elements together?
2. **Pick the shortest unambiguous label** -- abbreviate when the abbreviation is widely understood (e.g., `iac` for Infrastructure-as-Code, `aws` for Amazon Web Services, `lambda` for AWS Lambda)
3. **Use the prefix as the first segment** -- everything after the prefix narrows the scope

### 2.2 Prefix Examples from This Project

| Prefix | Domain | Elements |
|--------|--------|----------|
| `aws-` | AWS platform agents | `aws-architect`, `aws-developer`, `aws-cost-analyst`, `aws-security-auditor`, `aws-explorer`, `aws-librarian` |
| `iac-` | Infrastructure-as-Code specialists | `iac-terraform`, `iac-cfn`, `iac-sam`, `iac-sls-v3`, `iac-sls-v4` |
| `lambda-` | Lambda handler experts | `lambda-ts`, `lambda-python`, `lambda-go` |
| `terraform-` | Terraform skills | `terraform-style-guide`, `terraform-test` |

### 2.3 When NOT to Prefix

- **Standalone elements** with no siblings in the same domain do not need a prefix. Use a descriptive name instead: `docs-writer`, `incident-responder`, `ai-sensei`.
- **Do not force a prefix** on a single element just because it might gain siblings later. Add the prefix when the second element arrives and rename both.

---

## 3. Name Construction Pattern

Names follow this structure:

```
<prefix>-<specifier>[-<qualifier>]
```

| Segment | Purpose | Examples |
|---------|---------|----------|
| `prefix` | Groups related elements | `aws`, `iac`, `lambda` |
| `specifier` | Distinguishes within the group | `architect`, `terraform`, `ts` |
| `qualifier` | Optional version or variant | `v3`, `v4` |

### 3.1 Keep It Short

- Prefer `ts` over `typescript`, `cfn` over `cloudformation`, `sls` over `serverless`
- Drop filler words: `expert`, `specialist`, `handler` -- the context (agents directory, skills directory) already conveys the type
- Target 2--3 segments. If you reach 4+, look for a shorter abbreviation

### 3.2 Abbreviation Reference

Common abbreviations used in this project:

| Abbreviation | Full form |
|-------------|-----------|
| `aws` | Amazon Web Services |
| `iac` | Infrastructure as Code |
| `cfn` | CloudFormation |
| `sam` | Serverless Application Model |
| `sls` | Serverless Framework |
| `ts` | TypeScript |
| `py` | Python (use `python` for agents for clarity) |
| `go` | Go language |
| `tf` | Terraform (use `terraform` for agents for clarity) |

---

## 4. Decision Checklist

Use this checklist when naming a new agent, skill, or command:

1. **Is there already an element in the same domain?**
   - Yes → use the same prefix. If the existing element lacks a prefix, rename both.
   - No → use a plain descriptive name for now.

2. **Is the name short enough?**
   - Target: 2--3 hyphen-separated segments, under 25 characters.
   - If longer, abbreviate the specifier (see table above).

3. **Does it sort next to its siblings?**
   - Run `ls agents/` or `ls skills/` -- related elements should appear consecutively.

4. **Does it pass the regex?**
   - `^[a-z0-9]+(-[a-z0-9]+)*$` -- no uppercase, no underscores, no consecutive hyphens.

---

## 5. Renaming Procedure

When adding a second element to a domain that forces a prefix rename:

1. Choose the prefix (shortest unambiguous label)
2. Rename the existing element and the new one to use the prefix
3. Update **all references** across:
   - Agent frontmatter `task` permission maps
   - Agent `description` fields and system prompt body text
   - Skill content that mentions agent names
   - `AGENT_DELEGATION_SCHEMA.md` and `README.md`
4. Run `./scripts/validate-agents.sh --verbose` to confirm no broken references
5. Run `./scripts/apply-global-opencode.sh` to sync to global config
6. Remove stale old-name files from `~/.config/opencode/agents/` or `~/.config/opencode/skills/` (the apply script does not prune deleted files)
