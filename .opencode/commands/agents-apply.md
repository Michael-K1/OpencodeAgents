---
description: Apply repo agents, skills, and commands to global OpenCode config
---

Apply agents, skills, and commands from this project repository to the global OpenCode configuration at `~/.config/opencode/`.

**Targets** (repo root → global config):
- Agents: `agents/*.md` → `~/.config/opencode/agents/`
- Skills: `skills/*/SKILL.md` → `~/.config/opencode/skills/`
- Commands: `commands/*.md` → `~/.config/opencode/commands/`

**Arguments provided:** $ARGUMENTS

## Modes

### Default (no arguments, or `--verbose` / `--dry-run`)

Run the apply script based on the arguments:
- If no arguments were provided: run `./scripts/apply-global-opencode.sh` to apply all changes
- If "dry-run" or "--dry-run": run `./scripts/apply-global-opencode.sh --dry-run` to preview changes
- If "--verbose" or "-v": add the `--verbose` flag

Report the results to the user in a clear summary table.

### Force (`--force`)

Force mode **overwrites** the global config to match the repo exactly. This includes **deleting** global files that do not exist in the repo.

**Before making any changes**, you MUST:

1. **Compare** every category (agents, skills, commands) between the repo and global config:
   - List all files in the repo source directory
   - List all files in the global target directory
   - For each file, determine the status: `added`, `updated`, `unchanged`, `deleted`
     - `added` — exists in repo but not in global
     - `updated` — exists in both but content differs (use `diff -q`)
     - `unchanged` — exists in both and content is identical
     - `deleted` — exists in global but NOT in repo (will be removed)

2. **Show a summary table** to the user with these columns:

   | Category | Name | Status |
   |----------|------|--------|
   | agent | iac-terraform | unchanged |
   | agent | old-stale-agent | **DELETED** |
   | skill | opencode-agents | updated |
   | ... | ... | ... |

   Bold the `DELETED` entries so they stand out. Include counts at the bottom:
   `X added, Y updated, Z deleted, W unchanged`

3. **Ask permission** before proceeding. Use something like:
   > "This will modify X files and **permanently delete Z files** from `~/.config/opencode/`. Proceed? (yes/no)"

4. **Only if the user confirms**, execute the changes:
   - Run `./scripts/apply-global-opencode.sh` to handle adds and updates
   - Then `rm` each global file/directory that is not present in the repo
   - Report final results

If the user declines, abort with no changes.
