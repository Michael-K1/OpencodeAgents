---
description: Sync global OpenCode agents, skills, and commands to the project repo
---

Synchronize global OpenCode configuration from `~/.config/opencode/` to this project repository.

**Targets** (repo root, NOT `.opencode/`):
- Agents: `~/.config/opencode/agents/*.md` → `agents/`
- Skills: `~/.config/opencode/skills/*/SKILL.md` → `skills/`
- Commands: `~/.config/opencode/commands/*.md` → `commands/`

**Arguments provided:** $ARGUMENTS

Run the sync script based on the arguments:
- If no arguments were provided: run `./scripts/sync-global-opencode.sh --dry-run` to preview changes
- If "push": run `./scripts/sync-global-opencode.sh` to sync, commit, and push
- If "--no-push": run `./scripts/sync-global-opencode.sh --no-push` to sync and commit without pushing
- If "--verbose" or "-v": add the `--verbose` flag

Report the results to the user in a clear summary table.
