#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Polaris installer
# Copies skills, agents, and workflows into Claude config dirs
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.polaris.conf"
GLOBAL_CLAUDE_DIR="$HOME/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---- Helpers ----

info()  { echo -e "${BLUE}ℹ${NC}  $1"; }
ok()    { echo -e "${GREEN}✓${NC}  $1"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $1"; }
err()   { echo -e "${RED}✗${NC}  $1" >&2; }

usage() {
    cat <<EOF
Usage: ./install.sh <command> [options]

Commands:
  init                  First-time setup — saves repo location
  global                Install global skills to ~/.claude/
  project [--profile X] Install skills into current project's .claude/
  status                Show what's installed and if anything is stale
  list-profiles         List available profiles
  list-skills           List all available skills and agents

Options:
  --profile, -p NAME    Profile to install (see profiles/ dir)
  --extra, -e PATH      Additional skill to install (can be repeated)
  --dry-run, -n         Show what would be copied without copying
  --force, -f           Overwrite local modifications

Examples:
  ./install.sh init
  ./install.sh global
  ./install.sh project --profile django-api
  ./install.sh project --profile django-api --extra skills/misc/vfx.md
  ./install.sh project --profile fullstack
  ./install.sh status
EOF
    exit 1
}

# ---- Init ----

cmd_init() {
    echo "SKILLS_REPO=\"${SCRIPT_DIR}\"" > "$CONFIG_FILE"
    ok "Saved repo path to $CONFIG_FILE"
    ok "Repo: $SCRIPT_DIR"

    # Ensure global claude dir exists
    mkdir -p "$GLOBAL_CLAUDE_DIR"
    ok "Global Claude dir ready: $GLOBAL_CLAUDE_DIR"

    # Merge required settings into ~/.claude/settings.json
    _merge_settings
}

# ---- Settings merge ----

REQUIRED_SETTINGS='
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "MultiEdit",
      "Write",
      "Glob",
      "Grep",
      "LS",
      "Task",
      "WebFetch",
      "WebSearch",
      "Bash"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm -rf *)"
    ]
  },
  "enabledPlugins": {
    "pyright-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true
  }
}
'

_merge_settings() {
    local settings_file="$GLOBAL_CLAUDE_DIR/settings.json"

    if ! command -v jq &>/dev/null; then
        warn "jq not found — skipping settings.json merge"
        warn "Install with: brew install jq"
        warn "Then re-run: ./install.sh init"
        return 0
    fi

    if [[ -f "$settings_file" ]]; then
        # Merge: deduplicate arrays, merge objects
        local merged
        merged=$(jq -s '
            def merge_arrays: [.[0], .[1]] | add | unique;
            .[0] as $existing | .[1] as $required |
            $existing *
            {
                "permissions": {
                    "allow": ([$existing.permissions.allow // [], $required.permissions.allow] | add | unique),
                    "deny": ([$existing.permissions.deny // [], $required.permissions.deny] | add | unique)
                },
                "enabledPlugins": (($existing.enabledPlugins // {}) * $required.enabledPlugins)
            }
        ' "$settings_file" <(echo "$REQUIRED_SETTINGS"))

        echo "$merged" > "$settings_file"
        ok "Merged required settings into $settings_file"
    else
        echo "$REQUIRED_SETTINGS" | jq '.' > "$settings_file"
        ok "Created $settings_file with default settings"
    fi
}

# ---- Install helpers ----

ensure_init() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        err "Not initialized. Run './install.sh init' first."
        exit 1
    fi
    source "$CONFIG_FILE"
    if [[ ! -d "$SKILLS_REPO" ]]; then
        err "Skills repo not found at $SKILLS_REPO — re-run init."
        exit 1
    fi
}

# Copy a file from the repo to a target dir, preserving relative path under a namespace
copy_skill() {
    local src="$1"       # relative path in repo, e.g. skills/execution/django-patterns.md
    local dest_dir="$2"  # target root, e.g. /path/to/project/.claude
    local dry_run="${3:-false}"
    local force="${4:-false}"

    local dest="$dest_dir/polaris/$src"
    _copy_file "$src" "$dest" "$dry_run" "$force"
}

# Copy a file as a slash command (installed to .claude/commands/<name>.md)
copy_command() {
    local cmd_name="$1"  # command name, e.g. "react"
    local src="$2"       # relative path in repo
    local dest_dir="$3"  # target root, e.g. /path/to/project/.claude
    local dry_run="${4:-false}"
    local force="${5:-false}"

    local dest="$dest_dir/commands/${cmd_name}.md"
    _copy_file "$src" "$dest" "$dry_run" "$force"
}

# Shared copy logic with checksum comparison
_copy_file() {
    local src="$1"
    local dest="$2"
    local dry_run="${3:-false}"
    local force="${4:-false}"

    local dest_parent
    dest_parent="$(dirname "$dest")"

    # Check for local modifications
    if [[ -f "$dest" && "$force" != "true" ]]; then
        local src_hash dest_hash
        src_hash="$(shasum -a 256 "$SKILLS_REPO/$src" | cut -d' ' -f1)"
        dest_hash="$(shasum -a 256 "$dest" | cut -d' ' -f1)"
        if [[ "$src_hash" == "$dest_hash" ]]; then
            echo "  skip (unchanged): $src"
            return 0
        fi
        warn "  differs: $src (use --force to overwrite)"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "  would copy: $src → $dest"
        return 0
    fi

    mkdir -p "$dest_parent"
    cp "$SKILLS_REPO/$src" "$dest"
    ok "  copied: $src"
}

# Route a profile line to the right copy function
# Regular lines → copy_skill, "cmd:name=path" lines → copy_command
_install_line() {
    local line="$1"
    local dest_dir="$2"
    local dry_run="$3"
    local force="$4"

    if [[ "$line" == cmd:* ]]; then
        local cmd_part="${line#cmd:}"
        local cmd_name="${cmd_part%%=*}"
        local cmd_src="${cmd_part#*=}"
        copy_command "$cmd_name" "$cmd_src" "$dest_dir" "$dry_run" "$force"
    else
        copy_skill "$line" "$dest_dir" "$dry_run" "$force"
    fi
}

# Read a profile file and return the list of files
read_profile() {
    local profile_name="$1"
    local profile_file="$SKILLS_REPO/profiles/${profile_name}.txt"

    if [[ ! -f "$profile_file" ]]; then
        err "Profile not found: $profile_name"
        echo "Available profiles:"
        cmd_list_profiles
        exit 1
    fi

    # Read non-empty, non-comment lines
    grep -v '^\s*#' "$profile_file" | grep -v '^\s*$'
}

# ---- Commands ----

cmd_global() {
    ensure_init
    local dry_run="$1"
    local force="$2"

    info "Installing global skills to $GLOBAL_CLAUDE_DIR/"

    local profile_file="$SKILLS_REPO/profiles/global.txt"
    if [[ ! -f "$profile_file" ]]; then
        err "No global profile found at profiles/global.txt"
        exit 1
    fi

    while IFS= read -r line; do
        _install_line "$line" "$GLOBAL_CLAUDE_DIR" "$dry_run" "$force"
    done < <(read_profile "global")

    echo ""
    ok "Global install complete"
}

cmd_project() {
    ensure_init
    local profile="$1"
    local dry_run="$2"
    local force="$3"
    shift 3
    local extras=("$@")

    if [[ -z "$profile" ]]; then
        err "Specify a profile: ./install.sh project --profile <name>"
        echo ""
        cmd_list_profiles
        exit 1
    fi

    # Find project root (look for .git)
    local project_dir
    project_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -z "$project_dir" ]]; then
        err "Not inside a git repo. Run from your project directory."
        exit 1
    fi

    local claude_dir="$project_dir/.claude"
    mkdir -p "$claude_dir"

    info "Installing profile '$profile' to $claude_dir/"

    while IFS= read -r line; do
        _install_line "$line" "$claude_dir" "$dry_run" "$force"
    done < <(read_profile "$profile")

    # Install extra skills
    if [[ ${#extras[@]} -gt 0 ]]; then
        echo ""
        info "Installing ${#extras[@]} extra skill(s)..."
        for extra in "${extras[@]}"; do
            if [[ ! -f "$SKILLS_REPO/$extra" ]]; then
                err "  not found: $extra"
                continue
            fi
            _install_line "$extra" "$claude_dir" "$dry_run" "$force"
        done
    fi

    echo ""
    ok "Project install complete ($profile)"
    info "Files are in .claude/polaris/ — reference them from your CLAUDE.md"
}

cmd_status() {
    ensure_init

    echo ""
    info "Checking global installs ($GLOBAL_CLAUDE_DIR/polaris/)..."
    if [[ -d "$GLOBAL_CLAUDE_DIR/polaris" ]]; then
        find "$GLOBAL_CLAUDE_DIR/polaris" -type f -name "*.md" | while read -r dest; do
            local rel="${dest#$GLOBAL_CLAUDE_DIR/polaris/}"
            if [[ -f "$SKILLS_REPO/$rel" ]]; then
                local src_hash dest_hash
                src_hash="$(shasum -a 256 "$SKILLS_REPO/$rel" | cut -d' ' -f1)"
                dest_hash="$(shasum -a 256 "$dest" | cut -d' ' -f1)"
                if [[ "$src_hash" == "$dest_hash" ]]; then
                    ok "  current: $rel"
                else
                    warn "  stale:   $rel"
                fi
            else
                warn "  orphan:  $rel (not in repo)"
            fi
        done
    else
        echo "  (nothing installed)"
    fi

    # Check global commands
    if [[ -d "$GLOBAL_CLAUDE_DIR/commands" ]]; then
        info "Checking global commands ($GLOBAL_CLAUDE_DIR/commands/)..."
        find "$GLOBAL_CLAUDE_DIR/commands" -type f -name "*.md" | while read -r dest; do
            local name
            name="$(basename "$dest" .md)"
            echo "  /${name} (on-demand command)"
        done
    fi

    # Check current project if in a git repo
    local project_dir
    project_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$project_dir" && -d "$project_dir/.claude/polaris" ]]; then
        echo ""
        info "Checking project installs ($project_dir/.claude/polaris/)..."
        find "$project_dir/.claude/polaris" -type f -name "*.md" | while read -r dest; do
            local rel="${dest#$project_dir/.claude/polaris/}"
            if [[ -f "$SKILLS_REPO/$rel" ]]; then
                local src_hash dest_hash
                src_hash="$(shasum -a 256 "$SKILLS_REPO/$rel" | cut -d' ' -f1)"
                dest_hash="$(shasum -a 256 "$dest" | cut -d' ' -f1)"
                if [[ "$src_hash" == "$dest_hash" ]]; then
                    ok "  current: $rel"
                else
                    warn "  stale:   $rel"
                fi
            else
                warn "  orphan:  $rel (not in repo)"
            fi
        done

        # Check project commands
        if [[ -d "$project_dir/.claude/commands" ]]; then
            echo ""
            info "Checking project commands ($project_dir/.claude/commands/)..."
            find "$project_dir/.claude/commands" -type f -name "*.md" | while read -r dest; do
                local name
                name="$(basename "$dest" .md)"
                echo "  /${name} (on-demand command)"
            done
        fi
    fi

    echo ""
}

cmd_list_profiles() {
    info "Available profiles:"
    for f in "$SCRIPT_DIR"/profiles/*.txt; do
        [[ -f "$f" ]] || continue
        local name
        name="$(basename "$f" .txt)"
        local count
        count="$(grep -cv '^\s*#\|^\s*$' "$f" 2>/dev/null || echo 0)"
        echo "  $name ($count files)"
    done
}

cmd_list_skills() {
    info "Skills:"
    find "$SCRIPT_DIR/skills" -name "*.md" -type f | sort | while read -r f; do
        echo "  ${f#$SCRIPT_DIR/}"
    done
    echo ""
    info "Agents:"
    find "$SCRIPT_DIR/agents" -name "*.md" -type f | sort | while read -r f; do
        echo "  ${f#$SCRIPT_DIR/}"
    done
    echo ""
    info "Workflows:"
    find "$SCRIPT_DIR/workflows" -name "*.md" -type f | sort | while read -r f; do
        echo "  ${f#$SCRIPT_DIR/}"
    done
}

# ---- Main ----

COMMAND="${1:-}"
shift || true

DRY_RUN="false"
FORCE="false"
PROFILE=""
EXTRAS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile|-p) PROFILE="$2"; shift 2 ;;
        --extra|-e)   EXTRAS+=("$2"); shift 2 ;;
        --dry-run|-n) DRY_RUN="true"; shift ;;
        --force|-f)   FORCE="true"; shift ;;
        *)            err "Unknown option: $1"; usage ;;
    esac
done

case "$COMMAND" in
    init)           cmd_init ;;
    global)         cmd_global "$DRY_RUN" "$FORCE" ;;
    project)        cmd_project "$PROFILE" "$DRY_RUN" "$FORCE" "${EXTRAS[@]+"${EXTRAS[@]}"}" ;;
    status)         cmd_status ;;
    list-profiles)  cmd_list_profiles ;;
    list-skills)    cmd_list_skills ;;
    *)              usage ;;
esac
