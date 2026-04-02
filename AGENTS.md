# AGENTS.md

This repository stores OpenCode agent and skill configurations as versionable
Markdown files with YAML frontmatter. There is no application code -- all files
are declarative configuration. Changes are validated by reviewing the resulting
Markdown/YAML structure, not by running a build or test suite.

## Repository Structure

```
agents/                     # Agent definitions (Markdown + YAML frontmatter)
  <agent-name>.md           # One file per agent, filename = agent name
skills/                     # Skill reference documents
  <skill-name>/             # Directory name must match `name` in frontmatter
    SKILL.md                # Skill content (uppercase filename, always SKILL.md)
commands/                   # Custom slash commands (Markdown)
  <command-name>.md         # One file per command, filename = /command-name
scripts/                    # Utility scripts
  validate-agents.sh        # Validate agent and skill configurations
  sync-global-opencode.sh   # Sync global ~/.config/opencode/ to this repo
package.json                # Declares @opencode-ai/plugin dependency (for future tools/plugins)
```

## Build / Lint / Test

There are no build, lint, or test commands. The repository contains only Markdown
and JSON configuration files.

- **Package manager**: Bun (install with `bun install`)
- **Validation**: Review YAML frontmatter manually -- ensure all required fields
  are present and values match the OpenCode schema
- **Single-file check**: Open the file and verify frontmatter parses as valid YAML
  between the `---` delimiters

## File Types and Their Conventions

### Agent Files (`agents/<name>.md`)

Required frontmatter fields and key ordering:

```yaml
---
description: Required. Brief sentence describing what the agent does.
mode: primary | subagent | all
model: provider/model-id
temperature: 0.0-2.0
color: "#hexcolor"
permission:
  edit: allow | ask | deny
  bash:
    "*": ask
    "safe-command *": allow
  webfetch: allow | ask | deny
  skill:
    "skill-name": allow
---
```

Body structure:
1. Opening identity paragraph with bold agent name
2. `## Core Knowledge` -- numbered list of expertise areas
3. `## Workflow` -- step-by-step process using `### Step N:` subsections
4. `## Configuration Formats` -- reference examples with fenced code blocks
5. `## Best Practices` -- numbered guidelines
6. Additional reference sections as needed

### Skill Files (`skills/<name>/SKILL.md`)

Required frontmatter fields and key ordering:

```yaml
---
name: skill-name
description: What this skill provides (1-1024 chars).
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: reference
---
```

Body structure:
1. `# Title` (H1) -- one per file
2. Brief introductory paragraph
3. Numbered sections: `## 1. Section Title`, `## 2. Section Title`, etc.
4. Horizontal rules (`---`) between major sections

### Skill Name Validation

Skill directory names and `name` frontmatter values must:
- Be 1-64 characters
- Use only lowercase alphanumeric characters and single hyphens
- Not start or end with a hyphen
- Not contain consecutive hyphens (`--`)
- Match regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

## Markdown Style

- **Headings**: `#` for top-level title (skills only), `##` for major sections, `###` for subsections
- **Bullets**: Use `-`, not `*`
- **Bold**: `**text**` for emphasis and labels in lists (e.g., `**Purpose**: ...`)
- **Em dashes**: Use `--` (double hyphen), not `—`
- **Code blocks**: Always use fenced blocks with a language specifier
  (`markdown`, `json`, `yaml`, `typescript`, `bash`)
- **Tables**: Pipe-delimited with header separator row
- **Line length**: No hard wrapping -- lines can be any length
- **Spacing**: One blank line before and after headings, code blocks, and tables
- **Trailing whitespace**: None

## YAML Frontmatter Style

- **Delimiter**: `---` on its own line (opening and closing)
- **Indentation**: 2 spaces for nested keys
- **Quoting**: Bare values by default; quote hex colors (`"#6366f1"`) and
  strings containing special YAML characters
- **Booleans**: Use `true`/`false`, not `yes`/`no`
- **Numbers**: Bare (no quotes) -- e.g., `temperature: 0.2`

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Agent files | `kebab-case.md` | `opencode-expert.md` |
| Skill directories | `kebab-case` | `opencode-agents/` |
| Skill files | `SKILL.md` (uppercase) | `SKILL.md` |
| Frontmatter keys | `camelCase` for multi-word options | `top_p`, `reasoningEffort` |
| Permission keys | `lowercase` | `edit`, `bash`, `webfetch` |
| Mode values | `lowercase` | `primary`, `subagent`, `all` |
| Model IDs | `provider/model-id` | `anthropic/claude-sonnet-4-5` |

## Permission Patterns

When defining bash permissions, put the wildcard catch-all first, then
specific overrides (last matching rule wins):

```yaml
permission:
  bash:
    "*": ask            # Default: ask for approval
    "git status*": allow  # Safe read-only commands
    "ls *": allow
    "git push*": deny   # Block dangerous commands
```

Task and skill permissions follow the same pattern:

```yaml
permission:
  task:
    "*": deny
    "explore": allow
  skill:
    "*": allow
    "internal-*": deny
```

## Adding a New Agent

1. Create `agents/<agent-name>.md` using kebab-case naming
2. Add YAML frontmatter with at least `description` (required)
3. Write the system prompt in the Markdown body
4. Verify the frontmatter parses correctly as YAML

## Adding a New Skill

1. Create directory `skills/<skill-name>/`
2. Create `skills/<skill-name>/SKILL.md`
3. Add frontmatter with `name` matching the directory name and `description`
4. Write reference content in the Markdown body using numbered `##` sections

## Adding Custom Tools or Plugins (Future)

When TypeScript tools or plugins are added:
- Place tools in a `tools/` directory as `.ts` files
- Place plugins in a `plugins/` directory as `.ts` files
- Use the `@opencode-ai/plugin` package for type-safe definitions
- The `package.json` already declares this dependency

## Commit Conventions

This repository uses [Conventional Commits](https://www.conventionalcommits.org/).
All commit messages must end with the `[Agent]` tag when authored by an AI agent.

Format: `<type>(<scope>): <description> [Agent]`

| Type | When to use |
|------|-------------|
| `feat` | New agent, skill, command, tool, or plugin |
| `fix` | Correct an error in configuration or content |
| `docs` | Documentation-only changes (e.g., AGENTS.md, README) |
| `refactor` | Restructure without changing behavior |
| `chore` | Maintenance (dependency updates, .gitignore, etc.) |

Scopes: `agent`, `skill`, `command`, `tool`, `plugin`, or omit for repo-wide changes.

Examples:
- `feat(agent): add code-reviewer agent [Agent]`
- `fix(skill): correct YAML frontmatter in opencode-agents [Agent]`
- `docs: update AGENTS.md with commit conventions [Agent]`

## Error Handling

- If an agent file has invalid YAML frontmatter, OpenCode will skip it silently
- Always validate that `description` is present -- agents without it will not
  be discoverable by other agents
- Skill `name` must exactly match the containing directory name or it will
  not be loaded
