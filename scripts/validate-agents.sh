#!/bin/bash

###############################################################################
# validate-agents
#
# Purpose: Validate OpenCode agent and skill configuration files for common
#          errors that silently break agents at runtime.
#
# Checks performed:
#   1. Agent files have valid YAML frontmatter with required 'description' field
#   2. Wildcard '*' is the FIRST entry in permission maps (bash, task, skill)
#   3. Task permission targets reference existing agent files
#   4. Skill directory names match naming convention and frontmatter 'name'
#   5. Skill files have required 'name' and 'description' frontmatter fields
#
# Usage:
#   ./scripts/validate-agents.sh                    # Validate repo files
#   ./scripts/validate-agents.sh --global           # Validate global config
#   ./scripts/validate-agents.sh --verbose          # Show all checks, not just failures
#   ./scripts/validate-agents.sh --agents-dir DIR   # Override agents directory
#   ./scripts/validate-agents.sh --skills-dir DIR   # Override skills directory
#
# Exit codes:
#   0 = all checks pass
#   1 = one or more validation errors found
#   2 = usage/configuration error
#
###############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GLOBAL_OPENCODE_HOME="${GLOBAL_OPENCODE_HOME:-$HOME/.config/opencode}"

# Defaults
AGENTS_DIR="$PROJECT_ROOT/agents"
SKILLS_DIR="$PROJECT_ROOT/skills"
VERBOSE=false
ERRORS=0
WARNINGS=0
CHECKS=0

###############################################################################
# Output helpers
###############################################################################

log_error() {
  echo -e "  ${RED}ERROR${NC}  $1"
  ERRORS=$((ERRORS + 1))
}

log_warn() {
  echo -e "  ${YELLOW}WARN${NC}   $1"
  WARNINGS=$((WARNINGS + 1))
}

log_ok() {
  if [[ "$VERBOSE" == true ]]; then
    echo -e "  ${GREEN}OK${NC}     $1"
  fi
}

log_section() {
  echo ""
  echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

log_file() {
  echo -e "${CYAN}  ▸ $1${NC}"
}

###############################################################################
# Argument parsing
###############################################################################

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)
      AGENTS_DIR="$GLOBAL_OPENCODE_HOME/agents"
      SKILLS_DIR="$GLOBAL_OPENCODE_HOME/skills"
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --agents-dir)
      AGENTS_DIR="$2"
      shift 2
      ;;
    --skills-dir)
      SKILLS_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--global] [--verbose] [--agents-dir DIR] [--skills-dir DIR]"
      echo ""
      echo "Options:"
      echo "  --global           Validate global config (~/.config/opencode/)"
      echo "  --verbose, -v      Show passing checks, not just failures"
      echo "  --agents-dir DIR   Override agents directory"
      echo "  --skills-dir DIR   Override skills directory"
      echo "  --help, -h         Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for usage"
      exit 2
      ;;
  esac
done

###############################################################################
# Prerequisite checks
###############################################################################

if [[ ! -d "$AGENTS_DIR" ]]; then
  echo -e "${RED}Error: Agents directory not found: $AGENTS_DIR${NC}"
  exit 2
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo -e "${YELLOW}Warning: Skills directory not found: $SKILLS_DIR (skipping skill validation)${NC}"
  SKILLS_DIR=""
fi

###############################################################################
# YAML frontmatter extraction
#
# Extracts the YAML frontmatter between --- delimiters from a markdown file.
# Outputs raw YAML lines to stdout.
###############################################################################

extract_frontmatter() {
  local file="$1"
  local in_frontmatter=false
  local line_num=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))

    if [[ $line_num -eq 1 ]]; then
      if [[ "$line" == "---" ]]; then
        in_frontmatter=true
        continue
      else
        # No frontmatter
        return 1
      fi
    fi

    if [[ "$in_frontmatter" == true ]]; then
      if [[ "$line" == "---" ]]; then
        return 0
      fi
      echo "$line"
    fi
  done < "$file"

  # Reached EOF without closing ---
  return 1
}

###############################################################################
# Check: wildcard ordering in permission maps
#
# In bash/task/skill permission blocks, '*' must be the FIRST key.
# OpenCode uses "last matching rule wins", so if '*' is last it overrides
# all specific patterns above it.
#
# This parser looks for permission map blocks and checks the position of '*'.
###############################################################################

check_wildcard_ordering() {
  local file="$1"
  local basename
  basename=$(basename "$file")

  local frontmatter
  if ! frontmatter=$(extract_frontmatter "$file"); then
    return  # No frontmatter to check
  fi

  # Parse each permission map section (bash, task, skill) looking for '*' position
  local current_map=""
  local first_key_in_map=""
  local found_wildcard_not_first=false
  local map_line_num=0

  while IFS= read -r line; do
    # Detect permission map headers: "  bash:", "  task:", "  skill:"
    # These are indented 2 spaces under "permission:" and followed by sub-keys
    if echo "$line" | grep -qE '^  (bash|task|skill):$'; then
      # Save previous map results
      if [[ -n "$current_map" && "$found_wildcard_not_first" == true ]]; then
        log_error "$basename: permission.$current_map has '*' but it is NOT the first entry (last-match-wins will override all specific rules)"
      fi

      current_map=$(echo "$line" | sed 's/^  \(.*\):$/\1/')
      first_key_in_map=""
      found_wildcard_not_first=false
      map_line_num=0
      continue
    fi

    # Detect end of a map section (line not indented at 4+ spaces, or new section)
    if [[ -n "$current_map" ]]; then
      # Check if this line is a key in the current map (indented 4 spaces)
      if echo "$line" | grep -qE '^    ".*":'; then
        map_line_num=$((map_line_num + 1))
        local key
        key=$(echo "$line" | sed 's/^    "\(.*\)":.*$/\1/')

        if [[ $map_line_num -eq 1 ]]; then
          first_key_in_map="$key"
        fi

        if [[ "$key" == "*" && $map_line_num -gt 1 ]]; then
          found_wildcard_not_first=true
        fi
      elif echo "$line" | grep -qE '^  [a-z]' || echo "$line" | grep -qE '^[a-z]' || [[ -z "$line" ]]; then
        # End of current map
        if [[ "$found_wildcard_not_first" == true ]]; then
          log_error "$basename: permission.$current_map has '*' but it is NOT the first entry (last-match-wins will override all specific rules)"
        elif [[ $map_line_num -gt 0 && "$first_key_in_map" == "*" ]]; then
          log_ok "$basename: permission.$current_map has '*' as first entry"
        fi
        current_map=""
      fi
    fi
  done <<< "$frontmatter"

  # Check the last map (if file ends while inside a map)
  if [[ -n "$current_map" ]]; then
    if [[ "$found_wildcard_not_first" == true ]]; then
      log_error "$basename: permission.$current_map has '*' but it is NOT the first entry (last-match-wins will override all specific rules)"
    elif [[ $map_line_num -gt 0 && "$first_key_in_map" == "*" ]]; then
      log_ok "$basename: permission.$current_map has '*' as first entry"
    fi
  fi
}

###############################################################################
# Check: task permission targets reference existing agents
###############################################################################

check_task_targets() {
  local file="$1"
  local basename
  basename=$(basename "$file")

  local frontmatter
  if ! frontmatter=$(extract_frontmatter "$file"); then
    return
  fi

  # Collect all agent names from the agents directory
  local agent_names=()
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue
    local name
    name=$(basename "$agent_file" .md)
    agent_names+=("$name")
  done

  # Also include "explore" and "general" as valid built-in subagent types
  local builtin_agents=("explore" "general")

  # Parse task permission entries
  local in_task=false

  while IFS= read -r line; do
    if echo "$line" | grep -qE '^  task:$'; then
      in_task=true
      continue
    fi

    if [[ "$in_task" == true ]]; then
      if echo "$line" | grep -qE '^    ".*":'; then
        local target
        target=$(echo "$line" | sed 's/^    "\(.*\)":.*$/\1/')

        # Skip wildcard
        if [[ "$target" == "*" ]]; then
          continue
        fi

        # Check if target exists as an agent file or is a builtin
        local found=false

        for name in "${agent_names[@]}"; do
          if [[ "$name" == "$target" ]]; then
            found=true
            break
          fi
        done

        if [[ "$found" == false ]]; then
          for name in "${builtin_agents[@]}"; do
            if [[ "$name" == "$target" ]]; then
              found=true
              break
            fi
          done
        fi

        if [[ "$found" == true ]]; then
          log_ok "$basename: task target '$target' exists"
        else
          log_error "$basename: task permission references '$target' but no agent file '$target.md' found in $AGENTS_DIR"
        fi
      elif echo "$line" | grep -qE '^  [a-z]' || echo "$line" | grep -qE '^[a-z]'; then
        in_task=false
      fi
    fi
  done <<< "$frontmatter"
}

###############################################################################
# Check: required frontmatter fields for agents
###############################################################################

check_agent_frontmatter() {
  local file="$1"
  local basename
  basename=$(basename "$file")

  local frontmatter
  if ! frontmatter=$(extract_frontmatter "$file"); then
    log_error "$basename: no valid YAML frontmatter found (must start with '---' on line 1)"
    return
  fi

  ((CHECKS++)) || true

  # Check for 'description' field
  if echo "$frontmatter" | grep -qE '^description:'; then
    log_ok "$basename: has 'description' field"
  else
    log_error "$basename: missing required 'description' field (agents without it are not discoverable)"
  fi

  # Check for valid mode if present
  local mode
  mode=$(echo "$frontmatter" | grep -E '^mode:' | sed 's/^mode: *//' || true)
  if [[ -n "$mode" ]]; then
    case "$mode" in
      primary|subagent|all)
        log_ok "$basename: mode '$mode' is valid"
        ;;
      *)
        log_error "$basename: invalid mode '$mode' (must be: primary, subagent, or all)"
        ;;
    esac
  fi

  # Check temperature range if present
  local temp
  temp=$(echo "$frontmatter" | grep -E '^temperature:' | sed 's/^temperature: *//' || true)
  if [[ -n "$temp" ]]; then
    if awk "BEGIN {exit !($temp >= 0.0 && $temp <= 2.0)}" 2>/dev/null; then
      log_ok "$basename: temperature $temp is in valid range"
    else
      log_error "$basename: temperature $temp is out of range (must be 0.0-2.0)"
    fi
  fi

  # Check that permission block uses correct keys
  local perm_keys
  perm_keys=$(echo "$frontmatter" | grep -E '^  [a-z]+:' | sed 's/^  \([a-z]*\):.*/\1/' || true)
  local valid_perm_keys=("edit" "bash" "webfetch" "websearch" "task" "skill")

  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    local valid=false
    for vk in "${valid_perm_keys[@]}"; do
      if [[ "$key" == "$vk" ]]; then
        valid=true
        break
      fi
    done
    if [[ "$valid" == true ]]; then
      log_ok "$basename: permission key '$key' is valid"
    else
      # Only warn -- could be a non-permission key at 2-space indent
      # (e.g., under 'description: >' continuation). Don't error.
      :
    fi
  done <<< "$perm_keys"
}

###############################################################################
# Check: skill directory naming and frontmatter
###############################################################################

check_skill() {
  local skill_dir="$1"
  local dirname
  dirname=$(basename "$skill_dir")

  local skill_file="$skill_dir/SKILL.md"

  # Check SKILL.md exists
  if [[ ! -f "$skill_file" ]]; then
    log_error "skill/$dirname: missing SKILL.md file"
    return
  fi

  ((CHECKS++)) || true

  # Validate directory name matches convention: ^[a-z0-9]+(-[a-z0-9]+)*$
  if echo "$dirname" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    log_ok "skill/$dirname: directory name follows naming convention"
  else
    log_error "skill/$dirname: directory name '$dirname' violates naming convention (must be lowercase alphanumeric with single hyphens, no leading/trailing hyphens)"
  fi

  # Check name length (1-64 chars)
  local name_len=${#dirname}
  if [[ $name_len -gt 64 ]]; then
    log_error "skill/$dirname: name is $name_len chars (max 64)"
  fi

  # Extract frontmatter
  local frontmatter
  if ! frontmatter=$(extract_frontmatter "$skill_file"); then
    log_error "skill/$dirname: SKILL.md has no valid YAML frontmatter"
    return
  fi

  # Check for 'name' field
  local fm_name
  fm_name=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name: *//' || true)
  if [[ -z "$fm_name" ]]; then
    log_error "skill/$dirname: SKILL.md missing required 'name' field in frontmatter"
  elif [[ "$fm_name" != "$dirname" ]]; then
    log_error "skill/$dirname: frontmatter name '$fm_name' does not match directory name '$dirname'"
  else
    log_ok "skill/$dirname: frontmatter name matches directory name"
  fi

  # Check for 'description' field
  if echo "$frontmatter" | grep -qE '^description:'; then
    log_ok "skill/$dirname: has 'description' field"
  else
    log_error "skill/$dirname: SKILL.md missing required 'description' field"
  fi
}

###############################################################################
# Main
###############################################################################

echo ""
echo -e "${BLUE}OpenCode Agent & Skill Validator${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "  Agents: $AGENTS_DIR"
echo "  Skills: $SKILLS_DIR"

# ── Validate agents ──────────────────────────────────────────────────────────

log_section "Agent Validation"

agent_count=0
for agent_file in "$AGENTS_DIR"/*.md; do
  [[ -f "$agent_file" ]] || continue
  agent_count=$((agent_count + 1))
  log_file "$(basename "$agent_file")"
  check_agent_frontmatter "$agent_file"
  check_wildcard_ordering "$agent_file"
  check_task_targets "$agent_file"
done

if [[ $agent_count -eq 0 ]]; then
  log_warn "No agent files found in $AGENTS_DIR"
fi

# ── Validate skills ──────────────────────────────────────────────────────────

if [[ -n "$SKILLS_DIR" ]]; then
  log_section "Skill Validation"

  skill_count=0
  for skill_dir in "$SKILLS_DIR"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_count=$((skill_count + 1))
    log_file "$(basename "$skill_dir")/"
    check_skill "$skill_dir"
  done

  if [[ $skill_count -eq 0 ]]; then
    log_warn "No skill directories found in $SKILLS_DIR"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────

log_section "Summary"

echo ""
echo "  Agents checked: $agent_count"
[[ -n "$SKILLS_DIR" ]] && echo "  Skills checked: $skill_count"
echo ""

if [[ $ERRORS -gt 0 ]]; then
  echo -e "  ${RED}✗ $ERRORS error(s)${NC}, $WARNINGS warning(s)"
  echo ""
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "  ${GREEN}✓ All checks passed${NC} with ${YELLOW}$WARNINGS warning(s)${NC}"
  echo ""
  exit 0
else
  echo -e "  ${GREEN}✓ All checks passed${NC}"
  echo ""
  exit 0
fi
