---
description: Apply repo agents, skills, and commands to global OpenCode config
---

Apply agents, skills, and commands from this project repository to the global OpenCode configuration at `~/.config/opencode/`.

**Targets** (repo root → global config):
- Agents: `agents/*.md` → `~/.config/opencode/agents/`
- Skills: `skills/*/SKILL.md` → `~/.config/opencode/skills/`
- Commands: `commands/*.md` → `~/.config/opencode/commands/`

**Arguments provided:** $ARGUMENTS

Run the apply script based on the arguments:
- If no arguments were provided: run `./scripts/apply-global-opencode.sh` to apply all changes
- If "dry-run" or "--dry-run": run `./scripts/apply-global-opencode.sh --dry-run` to preview changes
- If "--verbose" or "-v": add the `--verbose` flag

Report the results to the user in a clear summary table.
