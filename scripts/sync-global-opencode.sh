#!/bin/bash

###############################################################################
# sync-global-opencode
#
# Purpose: Synchronize global OpenCode agents, skills, and commands from
#          ~/.config/opencode/ to the project repository, commit, and push.
#
# Usage:
#   ./scripts/sync-global-opencode.sh              # Sync, commit, and push
#   ./scripts/sync-global-opencode.sh --dry-run    # Show what would be synced
#   ./scripts/sync-global-opencode.sh --no-push    # Sync and commit, but don't push
#
# Environment:
#   GLOBAL_OPENCODE_HOME: Override default ~/.config/opencode location
#
###############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GLOBAL_OPENCODE_HOME="${GLOBAL_OPENCODE_HOME:-$HOME/.config/opencode}"
DRY_RUN=false
NO_PUSH=false
VERBOSE=false

# Counters
AGENTS_SYNCED=0
SKILLS_SYNCED=0
COMMANDS_SYNCED=0
AGENTS_UPDATED=0
SKILLS_UPDATED=0
COMMANDS_UPDATED=0

###############################################################################
# Functions
###############################################################################

print_usage() {
  cat << 'EOF'
Usage: sync-global-opencode.sh [OPTIONS]

Synchronize global OpenCode agents, skills, and commands to the project repository.

OPTIONS:
  --dry-run       Show what would be synced without making changes
  --no-push       Sync and commit, but don't push to remote
  -v, --verbose   Enable verbose output
  -h, --help      Show this help message

EXAMPLES:
  # Sync, commit, and push all changes
  ./scripts/sync-global-opencode.sh

  # Preview changes without modifying files
  ./scripts/sync-global-opencode.sh --dry-run

  # Sync and commit, but don't push
  ./scripts/sync-global-opencode.sh --no-push

ENVIRONMENT VARIABLES:
  GLOBAL_OPENCODE_HOME   Override global OpenCode directory (default: ~/.config/opencode)

EOF
}

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_header() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

log_section() {
  echo ""
  echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
}

verbose() {
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${BLUE}  → $1${NC}"
  fi
}

###############################################################################
# Validation
###############################################################################

validate_directories() {
  log_section "Validating directories"

  if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project root not found: $PROJECT_ROOT"
    exit 1
  fi
  verbose "Project root: $PROJECT_ROOT"

  if [[ ! -d "$GLOBAL_OPENCODE_HOME" ]]; then
    log_error "Global OpenCode home not found: $GLOBAL_OPENCODE_HOME"
    exit 1
  fi
  verbose "Global OpenCode home: $GLOBAL_OPENCODE_HOME"

  # Create project directories if they don't exist
  mkdir -p "$PROJECT_ROOT/agents" 2>/dev/null || true
  mkdir -p "$PROJECT_ROOT/skills" 2>/dev/null || true
  mkdir -p "$PROJECT_ROOT/commands" 2>/dev/null || true

  log_success "Directories validated"
}

###############################################################################
# Synchronization Functions
###############################################################################

sync_agents() {
  log_section "Syncing agents"

  local global_agents_dir="$GLOBAL_OPENCODE_HOME/agents"
  local project_agents_dir="$PROJECT_ROOT/agents"

  if [[ ! -d "$global_agents_dir" ]]; then
    log_warning "No agents found in global OpenCode home"
    return
  fi

  local agent_count=0
  for agent_file in "$global_agents_dir"/*.md; do
    if [[ ! -f "$agent_file" ]]; then
      continue
    fi

    local agent_name=$(basename "$agent_file")
    local target_file="$project_agents_dir/$agent_name"
    agent_count=$((agent_count + 1))

    if [[ "$DRY_RUN" == true ]]; then
      if [[ -f "$target_file" ]]; then
        if ! diff -q "$agent_file" "$target_file" > /dev/null 2>&1; then
          verbose "[WOULD UPDATE] $agent_name"
          AGENTS_UPDATED=$((AGENTS_UPDATED + 1))
        fi
      else
        verbose "[WOULD ADD] $agent_name"
        AGENTS_SYNCED=$((AGENTS_SYNCED + 1))
      fi
    else
      if [[ -f "$target_file" ]] && diff -q "$agent_file" "$target_file" > /dev/null 2>&1; then
        verbose "[UNCHANGED] $agent_name"
      else
        if [[ -f "$target_file" ]]; then
          AGENTS_UPDATED=$((AGENTS_UPDATED + 1))
          verbose "[UPDATED] $agent_name"
        else
          AGENTS_SYNCED=$((AGENTS_SYNCED + 1))
          verbose "[ADDED] $agent_name"
        fi
        cp "$agent_file" "$target_file"
      fi
    fi
  done

  if [[ $AGENTS_SYNCED -gt 0 ]] || [[ $AGENTS_UPDATED -gt 0 ]]; then
    log_success "Processed $agent_count agent(s) ($AGENTS_SYNCED new, $AGENTS_UPDATED updated)"
  else
    log_success "All agents up to date"
  fi
}

sync_skills() {
  log_section "Syncing skills"

  local global_skills_dir="$GLOBAL_OPENCODE_HOME/skills"
  local project_skills_dir="$PROJECT_ROOT/skills"

  if [[ ! -d "$global_skills_dir" ]]; then
    log_warning "No skills found in global OpenCode home"
    return
  fi

  local skill_count=0
  for skill_dir in "$global_skills_dir"/*/; do
    if [[ ! -d "$skill_dir" ]]; then
      continue
    fi

    local skill_name=$(basename "$skill_dir")
    local target_skill_dir="$project_skills_dir/$skill_name"
    skill_count=$((skill_count + 1))

    mkdir -p "$target_skill_dir" 2>/dev/null || true

    if [[ -f "$skill_dir/SKILL.md" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        if [[ -f "$target_skill_dir/SKILL.md" ]]; then
          if ! diff -q "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md" > /dev/null 2>&1; then
            verbose "[WOULD UPDATE] $skill_name"
            SKILLS_UPDATED=$((SKILLS_UPDATED + 1))
          fi
        else
          verbose "[WOULD ADD] $skill_name"
          SKILLS_SYNCED=$((SKILLS_SYNCED + 1))
        fi
      else
        if [[ -f "$target_skill_dir/SKILL.md" ]] && diff -q "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md" > /dev/null 2>&1; then
          verbose "[UNCHANGED] $skill_name"
        else
          if [[ -f "$target_skill_dir/SKILL.md" ]]; then
            SKILLS_UPDATED=$((SKILLS_UPDATED + 1))
            verbose "[UPDATED] $skill_name"
          else
            SKILLS_SYNCED=$((SKILLS_SYNCED + 1))
            verbose "[ADDED] $skill_name"
          fi
          cp "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md"
        fi
      fi
    fi
  done

  if [[ $SKILLS_SYNCED -gt 0 ]] || [[ $SKILLS_UPDATED -gt 0 ]]; then
    log_success "Processed $skill_count skill(s) ($SKILLS_SYNCED new, $SKILLS_UPDATED updated)"
  else
    log_success "All skills up to date"
  fi
}

sync_commands() {
  log_section "Syncing commands"

  local global_commands_dir="$GLOBAL_OPENCODE_HOME/commands"
  local project_commands_dir="$PROJECT_ROOT/commands"

  if [[ ! -d "$global_commands_dir" ]]; then
    log_warning "No commands found in global OpenCode home"
    return
  fi

  local command_count=0
  for command_file in "$global_commands_dir"/*.md; do
    if [[ ! -f "$command_file" ]]; then
      continue
    fi

    local command_name=$(basename "$command_file")
    local target_file="$project_commands_dir/$command_name"
    command_count=$((command_count + 1))

    if [[ "$DRY_RUN" == true ]]; then
      if [[ -f "$target_file" ]]; then
        if ! diff -q "$command_file" "$target_file" > /dev/null 2>&1; then
          verbose "[WOULD UPDATE] $command_name"
          COMMANDS_UPDATED=$((COMMANDS_UPDATED + 1))
        fi
      else
        verbose "[WOULD ADD] $command_name"
        COMMANDS_SYNCED=$((COMMANDS_SYNCED + 1))
      fi
    else
      if [[ -f "$target_file" ]] && diff -q "$command_file" "$target_file" > /dev/null 2>&1; then
        verbose "[UNCHANGED] $command_name"
      else
        if [[ -f "$target_file" ]]; then
          COMMANDS_UPDATED=$((COMMANDS_UPDATED + 1))
          verbose "[UPDATED] $command_name"
        else
          COMMANDS_SYNCED=$((COMMANDS_SYNCED + 1))
          verbose "[ADDED] $command_name"
        fi
        cp "$command_file" "$target_file"
      fi
    fi
  done

  if [[ $COMMANDS_SYNCED -gt 0 ]] || [[ $COMMANDS_UPDATED -gt 0 ]]; then
    log_success "Processed $command_count command(s) ($COMMANDS_SYNCED new, $COMMANDS_UPDATED updated)"
  else
    log_success "All commands up to date"
  fi
}

###############################################################################
# Git Operations
###############################################################################

commit_and_push() {
  log_section "Git operations"

  # Check if there are any changes (tracked or untracked)
  cd "$PROJECT_ROOT"

  local has_tracked_changes=false
  local has_untracked_files=false

  if ! git diff --quiet --exit-code 2>/dev/null || ! git diff --quiet --cached --exit-code 2>/dev/null; then
    has_tracked_changes=true
  fi

  # Check for untracked files in target directories (git diff misses these)
  if [[ -n "$(git ls-files --others --exclude-standard agents/ skills/ commands/ 2>/dev/null)" ]]; then
    has_untracked_files=true
  fi

  if [[ "$has_tracked_changes" == false && "$has_untracked_files" == false ]]; then
    log_success "No changes to commit"
    return 0
  fi

  # Stage changes
  verbose "Staging changes..."
  git add agents/ skills/ commands/ 2>/dev/null || true

  # Check again after staging
  if git diff --quiet --cached --exit-code 2>/dev/null; then
    log_success "No changes to commit"
    return 0
  fi

  # Build commit message
  local total_synced=$((AGENTS_SYNCED + SKILLS_SYNCED + COMMANDS_SYNCED))
  local total_updated=$((AGENTS_UPDATED + SKILLS_UPDATED + COMMANDS_UPDATED))
  local commit_msg="chore(sync): sync global agents, skills, and commands"

  if [[ $total_synced -gt 0 ]] || [[ $total_updated -gt 0 ]]; then
    commit_msg="$commit_msg\n\nSynced:\n"
    [[ $AGENTS_SYNCED -gt 0 ]] && commit_msg="$commit_msg- Added $AGENTS_SYNCED new agent(s)\n"
    [[ $AGENTS_UPDATED -gt 0 ]] && commit_msg="$commit_msg- Updated $AGENTS_UPDATED agent(s)\n"
    [[ $SKILLS_SYNCED -gt 0 ]] && commit_msg="$commit_msg- Added $SKILLS_SYNCED new skill(s)\n"
    [[ $SKILLS_UPDATED -gt 0 ]] && commit_msg="$commit_msg- Updated $SKILLS_UPDATED skill(s)\n"
    [[ $COMMANDS_SYNCED -gt 0 ]] && commit_msg="$commit_msg- Added $COMMANDS_SYNCED new command(s)\n"
    [[ $COMMANDS_UPDATED -gt 0 ]] && commit_msg="$commit_msg- Updated $COMMANDS_UPDATED command(s)\n"
    commit_msg="$commit_msg\n[Agent]"
  fi

  # Commit
  log_info "Committing changes..."
  echo -e "$commit_msg" | git commit -F - 2>/dev/null

  if [[ $? -eq 0 ]]; then
    log_success "Changes committed"
    verbose "$(git log -1 --oneline)"
  else
    log_warning "No changes to commit"
    return 0
  fi

  # Push
  if [[ "$NO_PUSH" != true ]]; then
    log_info "Pushing to remote..."
    if git push origin main 2>/dev/null; then
      log_success "Changes pushed to remote"
    else
      log_warning "Failed to push (may already be up to date)"
      return 1
    fi
  fi
}

###############################################################################
# Summary
###############################################################################

print_summary() {
  log_header "Sync Summary"

  local total_synced=$((AGENTS_SYNCED + SKILLS_SYNCED + COMMANDS_SYNCED))
  local total_updated=$((AGENTS_UPDATED + SKILLS_UPDATED + COMMANDS_UPDATED))
  local total=$((total_synced + total_updated))

  echo ""
  echo "Global OpenCode Home: $GLOBAL_OPENCODE_HOME"
  echo "Project Root:         $PROJECT_ROOT"
  echo ""
  echo "Agents:   +$AGENTS_SYNCED new, ~$AGENTS_UPDATED updated"
  echo "Skills:   +$SKILLS_SYNCED new, ~$SKILLS_UPDATED updated"
  echo "Commands: +$COMMANDS_SYNCED new, ~$COMMANDS_UPDATED updated"
  echo ""
  echo "Total:    +$total_synced new, ~$total_updated updated, = $total items"
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN MODE${NC} - No files were modified"
  elif [[ $total -eq 0 ]]; then
    echo -e "${GREEN}Everything is up to date${NC}"
  else
    echo -e "${GREEN}Sync completed successfully${NC}"
  fi

  echo ""
}

###############################################################################
# Main
###############################################################################

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --no-push)
        NO_PUSH=true
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        print_usage
        exit 1
        ;;
    esac
  done

  # Run workflow
  log_header "OpenCode Global Sync"
  echo "Starting synchronization..."
  echo ""

  validate_directories
  sync_agents
  sync_skills
  sync_commands

  if [[ "$DRY_RUN" != true ]]; then
    commit_and_push
  fi

  print_summary
}

# Run main
main "$@"
