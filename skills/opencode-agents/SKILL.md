---
name: opencode-agents
description: Comprehensive reference for creating and configuring OpenCode agents, skills, commands, custom tools, and plugins. Load this skill when you need detailed documentation on any OpenCode extension mechanism.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: reference
---

# OpenCode Agent Creation Reference

This skill provides the complete reference documentation for creating and configuring agents and companion resources in OpenCode.

---

## 1. Agent Types and Modes

### Primary Agents
- Selectable via the **Tab** key in the TUI
- Handle the main user conversation
- Built-in: **Build** (full tool access) and **Plan** (restricted, analysis only)

### Subagents
- Invoked via **@mention** in messages or automatically by primary agents via the **Task** tool
- Specialized for specific tasks
- Built-in: **General** (full tools except todo) and **Explore** (read-only)

### Mode Values
| Value | Tab key | @mention | Task tool |
|-------|---------|----------|-----------|
| `primary` | Yes | No | No |
| `subagent` | No | Yes | Yes |
| `all` | Yes | Yes | Yes |

Default mode (when omitted): `all`

### Hidden System Agents
- **compaction**: Compacts long context (auto, not selectable)
- **title**: Generates session titles (auto)
- **summary**: Creates session summaries (auto)

---

## 2. Configuration Formats

### Markdown Format

File locations:
- Global: `~/.config/opencode/agents/<name>.md`
- Project: `.opencode/agents/<name>.md`

The filename (without `.md`) becomes the agent name.

```markdown
---
description: Required. Brief description for auto-invocation.
mode: primary | subagent | all
model: provider/model-id
temperature: 0.0 - 1.0
top_p: 0.0 - 1.0
steps: number (max agentic iterations)
color: "#hex" or theme-color-name
hidden: true | false (subagent only, hides from @autocomplete)
disable: true | false
permission:
  edit: allow | ask | deny
  bash: allow | ask | deny | { pattern: action }
  webfetch: allow | ask | deny
  task: { pattern: action }
  skill: { pattern: action }
tools:
  toolname: true | false
---

System prompt content here...
```

### JSON Format

In `opencode.json` or `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "agent-name": {
      "description": "Required description",
      "mode": "subagent",
      "model": "provider/model-id",
      "prompt": "Inline prompt or {file:./path/to/prompt.txt}",
      "temperature": 0.3,
      "top_p": 0.9,
      "steps": 10,
      "color": "#ff6b6b",
      "hidden": false,
      "disable": false,
      "permission": {},
      "tools": {}
    }
  }
}
```

---

## 3. All Agent Options (Detailed)

### description (required)
Brief text describing what the agent does. Other agents use this to decide when to invoke it automatically.

### model
Format: `provider/model-id` (e.g., `anthropic/claude-sonnet-4-5`, `openai/gpt-5`, `opencode/gpt-5.1-codex`).
- Primary agents: default to the globally configured model
- Subagents: inherit from the invoking primary agent if not set

### prompt
System prompt. In JSON config, use `{file:./path}` to reference external files (path relative to config file location).

### temperature
Controls randomness. Range 0.0-1.0.
- 0.0-0.2: Deterministic (code analysis, config tasks)
- 0.3-0.5: Balanced (general development)
- 0.6-1.0: Creative (brainstorming)
- Default: 0 for most models, 0.55 for Qwen models

### top_p
Alternative to temperature for controlling diversity. Range 0.0-1.0.

### steps (max steps)
Maximum agentic iterations before forced text-only response. When reached, agent receives a system prompt to summarize work and recommend remaining tasks. Legacy field `maxSteps` is deprecated.

### mode
`primary`, `subagent`, or `all`. Default: `all`.

### hidden
Boolean. Only for subagents. Hides from @autocomplete. Agent can still be invoked by other agents via Task tool.

### color
Hex color (`#FF5733`) or theme name (`primary`, `secondary`, `accent`, `success`, `warning`, `error`, `info`).

### disable
Boolean. Set `true` to disable the agent entirely.

### Additional (passthrough)
Any unrecognized options pass through to the provider. Example: `reasoningEffort: "high"` for OpenAI reasoning models, `textVerbosity: "low"`.

---

## 4. Permission System

### Permission Values
- `allow`: Operation proceeds without approval
- `ask`: User prompted for approval
- `deny`: Operation blocked entirely

### Configurable Permission Keys
| Key | Controls |
|-----|----------|
| `edit` | All file modifications: edit, write, patch, multiedit |
| `bash` | Shell command execution |
| `webfetch` | Web content fetching |
| `task` | Which subagents can be invoked |
| `skill` | Which skills can be loaded |

### Bash Permissions with Glob Patterns
Last matching rule wins. Put `*` first, then specific overrides.

```yaml
permission:
  bash:
    "*": ask
    "git status*": allow
    "git log*": allow
    "grep *": allow
    "git push*": deny
```

### Task Permissions
Control which subagents an agent can invoke:

```yaml
permission:
  task:
    "*": deny
    "explore": allow
    "code-reviewer": ask
```

When set to `deny`, the subagent is removed from the Task tool description entirely.

### Skill Permissions
Control which skills can be loaded:

```yaml
permission:
  skill:
    "*": allow
    "internal-*": deny
    "experimental-*": ask
```

### Precedence
Agent-specific permissions override global permissions. Global permissions are set in `opencode.json` under `permission`.

---

## 5. Tools Reference

### Built-in Tools

| Tool | Purpose | Permission Key |
|------|---------|---------------|
| `bash` | Execute shell commands | `bash` |
| `edit` | String replacement in files | `edit` |
| `write` | Create/overwrite files | `edit` |
| `patch` | Apply patches | `edit` |
| `read` | Read file contents | `read` |
| `grep` | Regex search in files | `grep` |
| `glob` | Find files by pattern | `glob` |
| `list` | List directory contents | `list` |
| `skill` | Load SKILL.md content | `skill` |
| `todowrite` | Task list management | `todowrite` |
| `webfetch` | Fetch web content | `webfetch` |
| `websearch` | Web search (OpenCode/Exa) | `websearch` |
| `question` | Ask user questions | `question` |
| `lsp` | Code intelligence (experimental) | `lsp` |

### Disabling Tools (legacy `tools` field, deprecated)
```yaml
tools:
  write: false
  bash: false
  mymcp_*: false
```

Prefer the `permission` field instead. In `tools`, `true` = `{"*": "allow"}`, `false` = `{"*": "deny"}`.

### Custom Tools

Location: `.opencode/tools/<name>.ts` or `~/.config/opencode/tools/<name>.ts`

Structure:
```typescript
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "What this tool does",
  args: {
    param: tool.schema.string().describe("Parameter description"),
  },
  async execute(args, context) {
    // context: { agent, sessionID, messageID, directory, worktree }
    return "result"
  },
})
```

Multiple tools per file: use named exports. Creates `<filename>_<exportname>` tools.

Name collisions: custom tools override built-in tools with the same name.

### MCP Servers

Local MCP:
```json
{
  "mcp": {
    "server-name": {
      "type": "local",
      "command": ["npx", "-y", "package-name"],
      "enabled": true,
      "environment": { "KEY": "value" }
    }
  }
}
```

Remote MCP:
```json
{
  "mcp": {
    "server-name": {
      "type": "remote",
      "url": "https://mcp-server.com",
      "enabled": true,
      "headers": { "Authorization": "Bearer KEY" }
    }
  }
}
```

MCP tools are named `<servername>_<toolname>`. Control them with glob patterns: `"my-mcp*": false`.

Per-agent MCP control: disable globally in `tools`, enable in agent-specific `tools`.

---

## 6. Skills (SKILL.md)

### Purpose
On-demand knowledge that agents load via the `skill` tool. Avoids bloating context with always-present instructions.

### Location
- Project: `.opencode/skills/<name>/SKILL.md`
- Global: `~/.config/opencode/skills/<name>/SKILL.md`
- Claude-compatible: `.claude/skills/<name>/SKILL.md`, `~/.claude/skills/<name>/SKILL.md`
- Agent-compatible: `.agents/skills/<name>/SKILL.md`, `~/.agents/skills/<name>/SKILL.md`

### Structure
```markdown
---
name: skill-name
description: What this skill provides (1-1024 chars)
license: MIT (optional)
compatibility: opencode (optional)
metadata: (optional, string-to-string map)
  key: value
---

Skill content here...
```

### Name Validation Rules
- 1-64 characters
- Lowercase alphanumeric with single hyphen separators
- No leading/trailing hyphens
- No consecutive `--`
- Must match the directory name
- Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

### Discovery
OpenCode walks up from CWD to git worktree root, loading matching `skills/*/SKILL.md` from `.opencode/`, `.claude/`, and `.agents/` directories.

---

## 7. Custom Commands

### Purpose
Reusable prompts triggered via `/command-name` in the TUI.

### Location
- Project: `.opencode/commands/<name>.md`
- Global: `~/.config/opencode/commands/<name>.md`

### Markdown Format
```markdown
---
description: What this command does
agent: build (optional, defaults to current agent)
model: provider/model-id (optional)
subtask: true | false (optional, forces subagent invocation)
---

Command prompt template here.
Use $ARGUMENTS for all args, $1 $2 $3 for positional.
Use !`shell command` for shell output injection.
Use @filepath for file content inclusion.
```

### JSON Format
```json
{
  "command": {
    "command-name": {
      "template": "Prompt text with $ARGUMENTS",
      "description": "Description shown in TUI",
      "agent": "build",
      "model": "provider/model-id",
      "subtask": false
    }
  }
}
```

### Special Placeholders
- `$ARGUMENTS`: All arguments after the command name
- `$1`, `$2`, `$3`, ...: Individual positional arguments
- `` !`command` ``: Replaced with shell command output
- `@filepath`: Replaced with file contents

---

## 8. Plugins

### Purpose
Extend OpenCode by hooking into events. Can add custom tools, modify tool behavior, send notifications, inject environment variables.

### Location
- Project: `.opencode/plugins/<name>.ts`
- Global: `~/.config/opencode/plugins/<name>.ts`
- npm: Listed in `opencode.json` under `"plugin": ["package-name"]`

### Structure
```typescript
import type { Plugin } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {
  return {
    // Event hooks
    "tool.execute.before": async (input, output) => { },
    "tool.execute.after": async (input, output) => { },
    "session.idle": async (input) => { },
    "session.created": async (input) => { },
    "file.edited": async (input) => { },
    "shell.env": async (input, output) => { },
    "experimental.session.compacting": async (input, output) => { },

    // Custom tools
    tool: {
      mytool: tool({ description: "...", args: {}, async execute(args, ctx) { } }),
    },
  }
}
```

### Available Events
- **Command**: `command.executed`
- **File**: `file.edited`, `file.watcher.updated`
- **Message**: `message.part.removed`, `message.part.updated`, `message.removed`, `message.updated`
- **Permission**: `permission.asked`, `permission.replied`
- **Session**: `session.created`, `session.compacted`, `session.deleted`, `session.diff`, `session.error`, `session.idle`, `session.status`, `session.updated`
- **Shell**: `shell.env`
- **Tool**: `tool.execute.before`, `tool.execute.after`
- **TUI**: `tui.prompt.append`, `tui.command.execute`, `tui.toast.show`
- **Todo**: `todo.updated`
- **LSP**: `lsp.client.diagnostics`, `lsp.updated`
- **Installation**: `installation.updated`
- **Server**: `server.connected`

### Dependencies for Local Plugins
Add a `package.json` in `.opencode/` or `~/.config/opencode/` with required dependencies. OpenCode runs `bun install` at startup.

---

## 9. Rules (AGENTS.md)

### Purpose
Custom instructions included in the LLM's context for every conversation.

### Location & Precedence
1. Local: `AGENTS.md` in project root (or parent directories up to git root)
2. Global: `~/.config/opencode/AGENTS.md`
3. Claude-compatible fallback: `CLAUDE.md`, `~/.claude/CLAUDE.md`

### Additional Instructions
```json
{
  "instructions": [
    "CONTRIBUTING.md",
    "docs/guidelines.md",
    ".cursor/rules/*.md",
    "https://raw.githubusercontent.com/org/repo/main/rules.md"
  ]
}
```

Supports glob patterns and remote URLs (5s timeout).

### Initialize
Run `/init` in the TUI to auto-generate an `AGENTS.md` by scanning your project.

---

## 10. Config Locations & Precedence

1. Remote config (`.well-known/opencode`) -- organizational defaults
2. Global config (`~/.config/opencode/opencode.json`) -- user preferences
3. Custom config (`OPENCODE_CONFIG` env var) -- custom overrides
4. Project config (`opencode.json` in project root) -- project-specific
5. `.opencode` directories -- agents, commands, plugins
6. Inline config (`OPENCODE_CONFIG_CONTENT` env var) -- runtime overrides

Later sources override earlier ones for conflicting keys. Non-conflicting settings are preserved (merge, not replace).

### Directory Structure
```
~/.config/opencode/
  opencode.json        # Global config
  tui.json             # TUI config
  AGENTS.md            # Global rules
  agents/              # Global agents
  commands/            # Global commands
  skills/              # Global skills
  tools/               # Global custom tools
  plugins/             # Global plugins

<project>/
  opencode.json        # Project config
  AGENTS.md            # Project rules
  .opencode/
    agents/            # Project agents
    commands/          # Project commands
    skills/            # Project skills
    tools/             # Project custom tools
    plugins/           # Project plugins
    package.json       # Dependencies for local plugins/tools
```

---

## 11. Common Agent Patterns

### Read-Only Analysis Agent
```yaml
mode: subagent
permission:
  edit: deny
  bash:
    "*": deny
    "git log*": allow
    "git diff*": allow
```

### Full Development Agent
```yaml
mode: primary
permission:
  edit: allow
  bash: allow
  webfetch: allow
```

### Restricted Build Agent (ask before dangerous ops)
```yaml
mode: primary
permission:
  edit: allow
  bash:
    "*": allow
    "git push*": ask
    "rm -rf*": deny
    "docker *": ask
```

### Orchestrator Agent (controls subagent invocation)
```yaml
mode: primary
permission:
  task:
    "*": deny
    "explore": allow
    "code-reviewer": allow
    "docs-writer": allow
```

---

## 12. Model ID Format

Format: `provider/model-id`

Examples:
- `anthropic/claude-sonnet-4-5`
- `anthropic/claude-opus-4-6`
- `anthropic/claude-haiku-4-5`
- `openai/gpt-5`
- `openai/gpt-5.1-codex`
- `opencode/claude-sonnet-4-5` (via OpenCode Zen)
- `google/gemini-2.5-pro`

Run `opencode models` to list available models.

---

## 13. Variable Substitution in Config

### Environment Variables
`{env:VARIABLE_NAME}` -- replaced with env var value (empty string if unset)

### File Contents
`{file:path/to/file}` -- replaced with file contents. Path relative to config file or absolute (`/` or `~`).

---

## 14. Quick Start: Creating an Agent in 3 Steps

1. **Create the file**:
   ```bash
   mkdir -p ~/.config/opencode/agents
   # or: mkdir -p .opencode/agents
   ```

2. **Write the agent**:
   ```bash
   cat > ~/.config/opencode/agents/my-agent.md << 'EOF'
   ---
   description: What my agent does
   mode: all
   model: anthropic/claude-sonnet-4-5
   temperature: 0.3
   permission:
     edit: allow
     bash: allow
   ---

   You are a specialized agent for [task].

   ## Your Responsibilities
   - ...

   ## Process
   1. ...
   EOF
   ```

3. **Use it**: Tab to switch (if primary/all), `@my-agent` to mention, or let other agents invoke it via Task.

Alternatively, use the interactive command: `opencode agent create`
