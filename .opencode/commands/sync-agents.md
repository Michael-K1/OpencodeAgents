---
name: sync-agents
description: Sync global OpenCode agents, skills, and commands to the project repo and push
---

# Sync Global OpenCode Configuration

This command synchronizes global OpenCode agents, skills, and commands from `~/.config/opencode/` to the project repository.

## Usage

```
/sync-agents              # Preview changes (dry-run)
/sync-agents push         # Sync, commit, and push changes
/sync-agents --no-push    # Sync and commit without pushing
```

## What It Does

1. Validates global and project directories
2. Scans for new and updated:
   - Agents (`.md` files in `~/.config/opencode/agents/`)
   - Skills (in `~/.config/opencode/skills/`)
   - Commands (`.md` files in `~/.config/opencode/commands/`)
3. Copies changes to project `agents/`, `skills/`, `commands/` directories
4. Commits with descriptive message
5. Pushes to remote (if requested)

## Examples

### Preview Changes
```
/sync-agents
```

### Sync and Push
```
/sync-agents push
```

### Sync Without Push
```
/sync-agents --no-push
```

## Output

The command will show:
- ✓ Number of new agents/skills/commands added
- ~ Number of agents/skills/commands updated
- Summary of changes
- Git commit and push status

---

Executing sync operation...

!`cd $OPENCODE_AGENTS_REPO && git status`

## Global Configuration

**Global OpenCode Home**: `$GLOBAL_OPENCODE_HOME`
**Project Repository**: `$OPENCODE_AGENTS_REPO`

To specify custom paths, set environment variables:
```bash
export GLOBAL_OPENCODE_HOME=/custom/opencode/path
export OPENCODE_AGENTS_REPO=/custom/repo/path
```
