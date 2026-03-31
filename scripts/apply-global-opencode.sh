#!/bin/bash

###############################################################################
# apply-global-opencode
#
# Purpose: Apply agents, skills, and commands from the project repository
#          to the global OpenCode configuration at ~/.config/opencode/.
#          This is the reverse of sync-global-opencode.sh.
#
# Usage:
#   ./scripts/apply-global-opencode.sh              # Apply repo config to global
#   ./scripts/apply-global-opencode.sh --dry-run    # Show what would be applied
#   ./scripts/apply-global-opencode.sh --verbose    # Apply with verbose output
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
VERBOSE=false

# Counters
AGENTS_ADDED=0
SKILLS_ADDED=0
COMMANDS_ADDED=0
AGENTS_UPDATED=0
SKILLS_UPDATED=0
COMMANDS_UPDATED=0

###############################################################################
# Functions
###############################################################################

print_usage() {
  cat << 'EOF'
Usage: apply-global-opencode.sh [OPTIONS]

Apply agents, skills, and commands from the project repository to global
OpenCode configuration (~/.config/opencode/).

OPTIONS:
  --dry-run       Show what would be applied without making changes
  -v, --verbose   Enable verbose output
  -h, --help      Show this help message

EXAMPLES:
  # Apply all repo config to global
  ./scripts/apply-global-opencode.sh

  # Preview changes without modifying files
  ./scripts/apply-global-opencode.sh --dry-run

  # Apply with verbose output
  ./scripts/apply-global-opencode.sh --verbose

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
    log_info "Creating $GLOBAL_OPENCODE_HOME"
    mkdir -p "$GLOBAL_OPENCODE_HOME"
  fi
  verbose "Global OpenCode home: $GLOBAL_OPENCODE_HOME"

  # Create global directories if they don't exist
  if [[ "$DRY_RUN" != true ]]; then
    mkdir -p "$GLOBAL_OPENCODE_HOME/agents" 2>/dev/null || true
    mkdir -p "$GLOBAL_OPENCODE_HOME/skills" 2>/dev/null || true
    mkdir -p "$GLOBAL_OPENCODE_HOME/commands" 2>/dev/null || true
  fi

  log_success "Directories validated"
}

###############################################################################
# Apply Functions
###############################################################################

apply_agents() {
  log_section "Applying agents"

  local project_agents_dir="$PROJECT_ROOT/agents"
  local global_agents_dir="$GLOBAL_OPENCODE_HOME/agents"

  if [[ ! -d "$project_agents_dir" ]]; then
    log_warning "No agents directory found in project"
    return
  fi

  local agent_count=0
  for agent_file in "$project_agents_dir"/*.md; do
    if [[ ! -f "$agent_file" ]]; then
      continue
    fi

    local agent_name=$(basename "$agent_file")
    local target_file="$global_agents_dir/$agent_name"
    agent_count=$((agent_count + 1))

    if [[ "$DRY_RUN" == true ]]; then
      if [[ -f "$target_file" ]]; then
        if ! diff -q "$agent_file" "$target_file" > /dev/null 2>&1; then
          verbose "[WOULD UPDATE] $agent_name"
          AGENTS_UPDATED=$((AGENTS_UPDATED + 1))
        else
          verbose "[UNCHANGED] $agent_name"
        fi
      else
        verbose "[WOULD ADD] $agent_name"
        AGENTS_ADDED=$((AGENTS_ADDED + 1))
      fi
    else
      if [[ -f "$target_file" ]] && diff -q "$agent_file" "$target_file" > /dev/null 2>&1; then
        verbose "[UNCHANGED] $agent_name"
      else
        if [[ -f "$target_file" ]]; then
          AGENTS_UPDATED=$((AGENTS_UPDATED + 1))
          verbose "[UPDATED] $agent_name"
        else
          AGENTS_ADDED=$((AGENTS_ADDED + 1))
          verbose "[ADDED] $agent_name"
        fi
        cp "$agent_file" "$target_file"
      fi
    fi
  done

  if [[ $AGENTS_ADDED -gt 0 ]] || [[ $AGENTS_UPDATED -gt 0 ]]; then
    log_success "Processed $agent_count agent(s) ($AGENTS_ADDED new, $AGENTS_UPDATED updated)"
  else
    log_success "All agents up to date"
  fi
}

apply_skills() {
  log_section "Applying skills"

  local project_skills_dir="$PROJECT_ROOT/skills"
  local global_skills_dir="$GLOBAL_OPENCODE_HOME/skills"

  if [[ ! -d "$project_skills_dir" ]]; then
    log_warning "No skills directory found in project"
    return
  fi

  local skill_count=0
  for skill_dir in "$project_skills_dir"/*/; do
    if [[ ! -d "$skill_dir" ]]; then
      continue
    fi

    local skill_name=$(basename "$skill_dir")
    local target_skill_dir="$global_skills_dir/$skill_name"
    skill_count=$((skill_count + 1))

    if [[ "$DRY_RUN" != true ]]; then
      mkdir -p "$target_skill_dir" 2>/dev/null || true
    fi

    if [[ -f "$skill_dir/SKILL.md" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        if [[ -f "$target_skill_dir/SKILL.md" ]]; then
          if ! diff -q "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md" > /dev/null 2>&1; then
            verbose "[WOULD UPDATE] $skill_name"
            SKILLS_UPDATED=$((SKILLS_UPDATED + 1))
          else
            verbose "[UNCHANGED] $skill_name"
          fi
        else
          verbose "[WOULD ADD] $skill_name"
          SKILLS_ADDED=$((SKILLS_ADDED + 1))
        fi
      else
        if [[ -f "$target_skill_dir/SKILL.md" ]] && diff -q "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md" > /dev/null 2>&1; then
          verbose "[UNCHANGED] $skill_name"
        else
          if [[ -f "$target_skill_dir/SKILL.md" ]]; then
            SKILLS_UPDATED=$((SKILLS_UPDATED + 1))
            verbose "[UPDATED] $skill_name"
          else
            SKILLS_ADDED=$((SKILLS_ADDED + 1))
            verbose "[ADDED] $skill_name"
          fi
          cp "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md"
        fi
      fi
    else
      verbose "[SKIPPED] $skill_name (no SKILL.md)"
    fi
  done

  if [[ $SKILLS_ADDED -gt 0 ]] || [[ $SKILLS_UPDATED -gt 0 ]]; then
    log_success "Processed $skill_count skill(s) ($SKILLS_ADDED new, $SKILLS_UPDATED updated)"
  else
    log_success "All skills up to date"
  fi
}

apply_commands() {
  log_section "Applying commands"

  local project_commands_dir="$PROJECT_ROOT/commands"
  local global_commands_dir="$GLOBAL_OPENCODE_HOME/commands"

  if [[ ! -d "$project_commands_dir" ]]; then
    log_warning "No commands directory found in project"
    return
  fi

  local command_count=0
  for command_file in "$project_commands_dir"/*.md; do
    if [[ ! -f "$command_file" ]]; then
      continue
    fi

    local command_name=$(basename "$command_file")
    local target_file="$global_commands_dir/$command_name"
    command_count=$((command_count + 1))

    if [[ "$DRY_RUN" == true ]]; then
      if [[ -f "$target_file" ]]; then
        if ! diff -q "$command_file" "$target_file" > /dev/null 2>&1; then
          verbose "[WOULD UPDATE] $command_name"
          COMMANDS_UPDATED=$((COMMANDS_UPDATED + 1))
        else
          verbose "[UNCHANGED] $command_name"
        fi
      else
        verbose "[WOULD ADD] $command_name"
        COMMANDS_ADDED=$((COMMANDS_ADDED + 1))
      fi
    else
      if [[ -f "$target_file" ]] && diff -q "$command_file" "$target_file" > /dev/null 2>&1; then
        verbose "[UNCHANGED] $command_name"
      else
        if [[ -f "$target_file" ]]; then
          COMMANDS_UPDATED=$((COMMANDS_UPDATED + 1))
          verbose "[UPDATED] $command_name"
        else
          COMMANDS_ADDED=$((COMMANDS_ADDED + 1))
          verbose "[ADDED] $command_name"
        fi
        cp "$command_file" "$target_file"
      fi
    fi
  done

  if [[ $command_count -eq 0 ]]; then
    log_warning "No commands found in project"
  elif [[ $COMMANDS_ADDED -gt 0 ]] || [[ $COMMANDS_UPDATED -gt 0 ]]; then
    log_success "Processed $command_count command(s) ($COMMANDS_ADDED new, $COMMANDS_UPDATED updated)"
  else
    log_success "All commands up to date"
  fi
}

###############################################################################
# Summary
###############################################################################

print_summary() {
  log_header "Apply Summary"

  local total_added=$((AGENTS_ADDED + SKILLS_ADDED + COMMANDS_ADDED))
  local total_updated=$((AGENTS_UPDATED + SKILLS_UPDATED + COMMANDS_UPDATED))
  local total=$((total_added + total_updated))

  echo ""
  echo "Project Root:         $PROJECT_ROOT"
  echo "Global OpenCode Home: $GLOBAL_OPENCODE_HOME"
  echo ""
  echo "Agents:   +$AGENTS_ADDED new, ~$AGENTS_UPDATED updated"
  echo "Skills:   +$SKILLS_ADDED new, ~$SKILLS_UPDATED updated"
  echo "Commands: +$COMMANDS_ADDED new, ~$COMMANDS_UPDATED updated"
  echo ""
  echo "Total:    +$total_added new, ~$total_updated updated, = $total items"
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN MODE${NC} -- No files were modified"
  elif [[ $total -eq 0 ]]; then
    echo -e "${GREEN}Everything is up to date${NC}"
  else
    echo -e "${GREEN}Apply completed successfully${NC}"
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
  log_header "OpenCode Global Apply"
  if [[ "$DRY_RUN" == true ]]; then
    echo "Previewing changes (dry run)..."
  else
    echo "Applying repo configuration to global OpenCode..."
  fi
  echo ""

  validate_directories
  apply_agents
  apply_skills
  apply_commands
  print_summary
}

# Run main
main "$@"
