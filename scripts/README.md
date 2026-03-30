# Scripts Directory

Helper scripts for managing the OpenCode agents repository.

## sync-global-opencode.sh

**Purpose**: Synchronize global OpenCode agents, skills, and commands from `~/.config/opencode/` to the project repository, then commit and push the changes.

### Quick Start

```bash
# Sync, commit, and push all changes
./scripts/sync-global-opencode.sh

# Preview changes without making modifications
./scripts/sync-global-opencode.sh --dry-run

# Sync and commit, but don't push
./scripts/sync-global-opencode.sh --no-push

# Enable verbose output
./scripts/sync-global-opencode.sh -v
```

### What It Does

1. **Validates** both global and project directories
2. **Scans** `~/.config/opencode/agents`, `~/.config/opencode/skills`, `~/.config/opencode/commands`
3. **Compares** files with project versions to detect new and updated files
4. **Copies** new and updated files to `.opencode/agents/`, `.opencode/skills/`, `.opencode/commands/`
5. **Stages** changes with git
6. **Commits** with a descriptive message including sync statistics
7. **Pushes** to the remote repository (configurable)

### Features

- 🔍 **Automatic Detection**: Identifies new and updated agents/skills/commands
- 📊 **Detailed Summary**: Shows statistics of what was synced
- 🧪 **Dry Run Mode**: Preview changes without modifying files
- 📝 **Conventional Commits**: Uses `chore(sync):` prefix with detailed statistics
- 🎨 **Colored Output**: Easy-to-read colored logs with status indicators
- 🔇 **Verbose Mode**: Optional detailed output for debugging
- 🚫 **Optional Push**: Can sync and commit without pushing

### Usage Examples

#### Basic Sync
```bash
./scripts/sync-global-opencode.sh
```
Syncs all agents, skills, and commands, commits, and pushes.

**Output:**
```
═══════════════════════════════════════════════════════
OpenCode Global Sync
═══════════════════════════════════════════════════════
Starting synchronization...

──────────────────────────────────────────────────────
Validating directories
──────────────────────────────────────────────────────
✓ Directories validated

──────────────────────────────────────────────────────
Syncing agents
──────────────────────────────────────────────────────
✓ Processed 10 agent(s) (2 new, 3 updated)

──────────────────────────────────────────────────────
Syncing skills
──────────────────────────────────────────────────────
✓ Processed 1 skill(s) (0 new, 1 updated)

──────────────────────────────────────────────────────
Syncing commands
──────────────────────────────────────────────────────
ℹ No commands found in global OpenCode home

──────────────────────────────────────────────────────
Git operations
──────────────────────────────────────────────────────
ℹ Committing changes...
✓ Changes committed
ℹ Pushing to remote...
✓ Changes pushed to remote

═══════════════════════════════════════════════════════
Sync Summary
═══════════════════════════════════════════════════════

Global OpenCode Home: /home/user/.config/opencode
Project Root:         /path/to/OpencodeAgents

Agents:   +2 new, ~3 updated
Skills:   +0 new, ~1 updated
Commands: +0 new, ~0 updated

Total:    +2 new, ~4 updated, = 6 items

Sync completed successfully
```

#### Dry Run Preview
```bash
./scripts/sync-global-opencode.sh --dry-run
```
Shows what would be synced without making changes.

#### Verbose Mode
```bash
./scripts/sync-global-opencode.sh -v
```
Includes detailed output for each file.

#### Sync Without Push
```bash
./scripts/sync-global-opencode.sh --no-push
```
Syncs and commits, but doesn't push to remote.

### Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview changes without modifying files |
| `--no-push` | Sync and commit, but don't push to remote |
| `-v, --verbose` | Enable verbose output showing each file |
| `-h, --help` | Show help message |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GLOBAL_OPENCODE_HOME` | Override global OpenCode directory | `~/.config/opencode` |

**Example:**
```bash
GLOBAL_OPENCODE_HOME=/custom/path ./scripts/sync-global-opencode.sh
```

### What Gets Synced

- **Agents**: `~/.config/opencode/agents/*.md` → `.opencode/agents/`
- **Skills**: `~/.config/opencode/skills/**/SKILL.md` → `.opencode/skills/`
- **Commands**: `~/.config/opencode/commands/*.md` → `.opencode/commands/`

### Git Commit Format

The script follows [Conventional Commits](https://www.conventionalcommits.org/):

```
chore(sync): sync global agents, skills, and commands

Synced:
- Added 2 new agent(s)
- Updated 3 agent(s)
- Added 0 new skill(s)
- Updated 1 skill(s)

[Agent]
```

The `[Agent]` tag is automatically added to identify commits created by agents.

### Directory Structure

```
~/.config/opencode/              Global OpenCode home
├── agents/                      Global agent definitions
│   ├── aws-architect.md
│   ├── aws-developer.md
│   └── ...
├── skills/                      Global skills
│   └── skill-name/
│       └── SKILL.md
└── commands/                    Global commands
    ├── command-1.md
    └── command-2.md

OpencodeAgents/                  Project repository
└── .opencode/
    ├── agents/                  Project agent definitions
    ├── skills/                  Project skills
    └── commands/                Project commands
```

### When to Use

Use this script when:
- ✅ You've updated agents in the global OpenCode config
- ✅ You've added new skills globally
- ✅ You want to keep the project repo in sync with global changes
- ✅ You need to share updates with the team

### Troubleshooting

#### Script doesn't have execute permission
```bash
chmod +x ./scripts/sync-global-opencode.sh
```

#### Global OpenCode home not found
```bash
# Check if ~/.config/opencode exists
ls -la ~/.config/opencode/

# Or specify custom path
GLOBAL_OPENCODE_HOME=/custom/path ./scripts/sync-global-opencode.sh
```

#### Git push fails
```bash
# Check remote status
git remote -v
git status

# Sync without pushing first
./scripts/sync-global-opencode.sh --no-push
```

#### See what changed without modifying
```bash
./scripts/sync-global-opencode.sh --dry-run --verbose
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (directory validation failed or push failed) |

### Related Files

- `AGENT_DELEGATION_SCHEMA.md` - Agent orchestration architecture
- `AGENTS.md` - Repository configuration conventions
- `.opencode/agents/` - Project agent definitions
- `.opencode/skills/` - Project skill definitions
- `.opencode/commands/` - Project command definitions
