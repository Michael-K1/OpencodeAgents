---
name: sync-global
description: Sync global OpenCode agents, skills, and commands to project repo
---

# Sync Global OpenCode Configuration to Project

Synchronize agents, skills, and commands from global OpenCode (`~/.config/opencode/`) to the project repository, then commit and push.

## Usage

```bash
/sync-global              # Dry-run: preview what would sync
/sync-global push         # Execute sync with commit and push
/sync-global --no-push    # Execute sync with commit, but no push
/sync-global --verbose    # Show detailed output
```

## What Gets Synced

- **Agents**: `~/.config/opencode/agents/*.md` → `agents/`
- **Skills**: `~/.config/opencode/skills/*/SKILL.md` → `skills/`
- **Commands**: `~/.config/opencode/commands/*.md` → `commands/`

## Example Workflow

### 1. Preview Changes
```bash
/sync-global
```

Output:
```
Global OpenCode Home: /home/user/.config/opencode
Project Root: /path/to/OpencodeAgents

New agents: 2
Updated agents: 1
New skills: 0
Updated skills: 2
New commands: 0
Updated commands: 0

DRY RUN - No files modified
```

### 2. Execute Sync
```bash
/sync-global push
```

Output:
```
✓ Synced 2 new agents
✓ Updated 1 agent
✓ Updated 2 skills
✓ Committed changes
✓ Pushed to remote

Summary:
- Added 2 new agent(s)
- Updated 1 agent(s)
- Updated 2 skill(s)
Total: 5 changes
```

### 3. Sync Without Pushing
```bash
/sync-global --no-push
```

Same as above but stops after commit without pushing.

## Detailed Breakdown

### Step 1: Validate Directories
- Checks `~/.config/opencode/` exists
- Checks project root exists
- Creates local `agents/`, `skills/`, `commands/` if needed

### Step 2: Compare Files
- Scans global agents/skills/commands
- Compares with project versions
- Identifies new and updated items

### Step 3: Copy Changes
- Copies new agents/skills/commands
- Updates modified items
- Preserves file timestamps

### Step 4: Git Operations
- Stages changes
- Creates commit with statistics
- Pushes to remote (optional)

## Commit Message Format

```
chore(sync): sync global agents, skills, and commands

Synced:
- Added 2 new agent(s)
- Updated 1 agent(s)
- Added 0 new skill(s)
- Updated 2 skill(s)

[Agent]
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `GLOBAL_OPENCODE_HOME` | Global OpenCode home | `~/.config/opencode` |
| `PROJECT_ROOT` | Project repository root | Current git root |

## Statistics

The command tracks:
- ✓ New items added
- ~ Items updated
- ✓ Unchanged items
- ✗ Errors (if any)

## Integration

This command is designed to be run:
- Regularly to keep project in sync with global OpenCode changes
- After updating agents in the global config
- As part of CI/CD workflows
- Before pushing project updates to ensure consistency

## Notes

- Files are compared byte-for-byte to detect changes
- Only changed files are copied
- Git history is preserved
- Commit uses `[Agent]` tag for automated commits
- Script has `--dry-run` mode for safety
