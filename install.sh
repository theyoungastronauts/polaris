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
  project [--profile X] Install skills into a project's .claude/
  status                Show what's installed and if anything is stale
  list-profiles         List available profiles
  list-skills           List all available skills and agents

Options:
  --profile, -p NAME    Profile to install (see profiles/ dir)
  --target, -t DIR      Target directory (default: current git root)
  --extra, -e PATH      Additional skill to install (can be repeated)
  --dry-run, -n         Show what would be copied without copying
  --force, -f           Overwrite local modifications
  --fresh               Replace CLAUDE.md with defaults template + skills (global only)
  --no-claude-md        Skip CLAUDE.md generation

Examples:
  ./install.sh init
  ./install.sh global
  ./install.sh global --fresh
  ./install.sh project --profile django-api
  ./install.sh project --profile django-api --target ~/prj/my-app-api
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

    # Add shell alias
    _install_alias
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

# ---- Shell alias ----

ALIAS_LINE="alias polaris=\"${SCRIPT_DIR}/install.sh\""

_install_alias() {
    # Detect shell profile
    local profile=""
    case "$(basename "$SHELL")" in
        zsh)  profile="$HOME/.zshrc" ;;
        bash)
            if [[ -f "$HOME/.bash_profile" ]]; then
                profile="$HOME/.bash_profile"
            else
                profile="$HOME/.bashrc"
            fi
            ;;
        *)
            warn "Unknown shell ($SHELL) — add manually: $ALIAS_LINE"
            return 0
            ;;
    esac

    # Check if alias already exists
    if grep -qF 'alias polaris=' "$profile" 2>/dev/null; then
        # Update in case repo path changed
        local existing
        existing="$(grep 'alias polaris=' "$profile")"
        if [[ "$existing" == "$ALIAS_LINE" ]]; then
            ok "Shell alias already set in $profile"
        else
            # Replace the old alias line
            sed -i '' "s|alias polaris=.*|${ALIAS_LINE}|" "$profile"
            ok "Updated shell alias in $profile"
            info "Run: source $profile (or open a new terminal)"
        fi
    else
        echo "" >> "$profile"
        echo "# Polaris CLI" >> "$profile"
        echo "$ALIAS_LINE" >> "$profile"
        ok "Added 'polaris' alias to $profile"
        info "Run: source $profile (or open a new terminal)"
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

# Copy a file from the repo to a target dir, preserving relative path
copy_skill() {
    local src="$1"       # relative path in repo, e.g. skills/execution/django-patterns.md
    local dest_dir="$2"  # target root, e.g. /path/to/project/.claude
    local dry_run="${3:-false}"
    local force="${4:-false}"

    local dest="$dest_dir/$src"
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

# ---- CLAUDE.md generation ----

# Extract the first heading from a skill file as a human-readable title
_extract_title() {
    local rel_path="$1"
    local full_path="$SKILLS_REPO/$rel_path"
    if [[ -f "$full_path" ]]; then
        grep -m1 '^#\{1,2\} ' "$full_path" | sed 's/^#\{1,2\} //'
    else
        basename "$rel_path" .md
    fi
}

# Generate the marker-wrapped Polaris skills block from a profile
# Args: profile_name, path_note (e.g. "~/.claude/"), [extra1, extra2, ...]
_generate_polaris_block() {
    local profile_name="$1"
    local path_note="$2"
    shift 2
    local extras=("$@")

    local skills=() agents=() workflows=() templates=() commands=()

    # Categorize profile entries
    while IFS= read -r line; do
        if [[ "$line" == cmd:* ]]; then
            local cmd_part="${line#cmd:}"
            local cmd_name="${cmd_part%%=*}"
            commands+=("$cmd_name")
        elif [[ "$line" == skills/* ]]; then
            skills+=("$line")
        elif [[ "$line" == agents/* ]]; then
            agents+=("$line")
        elif [[ "$line" == workflows/* ]]; then
            workflows+=("$line")
        elif [[ "$line" == templates/* ]]; then
            templates+=("$line")
        fi
    done < <(read_profile "$profile_name")

    # Categorize extras
    for extra in "${extras[@]+"${extras[@]}"}"; do
        if [[ "$extra" == skills/* ]]; then
            skills+=("$extra")
        elif [[ "$extra" == agents/* ]]; then
            agents+=("$extra")
        elif [[ "$extra" == workflows/* ]]; then
            workflows+=("$extra")
        elif [[ "$extra" == templates/* ]]; then
            templates+=("$extra")
        fi
    done

    # Build block
    echo "<!-- polaris:start -->"
    echo "## Polaris Skills"
    echo ""
    echo "> Auto-generated by Polaris (profile: ${profile_name}). Do not edit between these markers."
    echo "> Files are relative to ${path_note}"
    echo ""
    echo "Read the relevant skill file when working on a related task."

    if [[ ${#skills[@]} -gt 0 ]]; then
        echo ""
        echo "**Skills:**"
        for s in "${skills[@]}"; do
            local title
            title="$(_extract_title "$s")"
            echo "- \`${s}\` — ${title}"
        done
    fi

    if [[ ${#agents[@]} -gt 0 ]]; then
        echo ""
        echo "**Agents:**"
        for a in "${agents[@]}"; do
            local title
            title="$(_extract_title "$a")"
            echo "- \`${a}\` — ${title}"
        done
    fi

    if [[ ${#workflows[@]} -gt 0 ]]; then
        echo ""
        echo "**Workflows:**"
        for w in "${workflows[@]}"; do
            local title
            title="$(_extract_title "$w")"
            echo "- \`${w}\` — ${title}"
        done
    fi

    if [[ ${#templates[@]} -gt 0 ]]; then
        echo ""
        echo "**Templates:**"
        for t in "${templates[@]}"; do
            local title
            title="$(_extract_title "$t")"
            echo "- \`${t}\` — ${title}"
        done
    fi

    if [[ ${#commands[@]} -gt 0 ]]; then
        echo ""
        echo "**On-demand commands** (invoke as slash commands):"
        for c in "${commands[@]}"; do
            echo "- \`/${c}\`"
        done
    fi

    echo "<!-- polaris:end -->"
}

# Update CLAUDE.md with the Polaris skills block
# Args: profile_name, claude_md_path, path_note, fresh, dry_run, [extras...]
_update_claude_md() {
    local profile_name="$1"
    local claude_md_file="$2"
    local path_note="$3"
    local fresh="$4"
    local dry_run="$5"
    shift 5
    local extras=("$@")

    local polaris_block
    polaris_block="$(_generate_polaris_block "$profile_name" "$path_note" "${extras[@]+"${extras[@]}"}")"

    echo ""
    info "Updating CLAUDE.md..."

    if [[ "$fresh" == "true" ]]; then
        _apply_claude_md_fresh "$claude_md_file" "$polaris_block" "$dry_run"
    else
        _apply_claude_md_amend "$claude_md_file" "$polaris_block" "$dry_run"
    fi
}

# Amend mode: insert or replace the Polaris block, preserving user content
_apply_claude_md_amend() {
    local claude_md_file="$1"
    local polaris_block="$2"
    local dry_run="$3"

    if [[ "$dry_run" == "true" ]]; then
        echo "  would update: $claude_md_file (amend Polaris section)"
        return 0
    fi

    if [[ ! -f "$claude_md_file" ]]; then
        echo "$polaris_block" > "$claude_md_file"
        ok "Created $claude_md_file with Polaris skills"
        return 0
    fi

    if grep -q '<!-- polaris:start -->' "$claude_md_file"; then
        # Replace existing Polaris section
        local preserved
        preserved=$(awk '
            /<!-- polaris:start -->/ { skip=1; next }
            /<!-- polaris:end -->/   { skip=0; next }
            !skip { print }
        ' "$claude_md_file")

        # Trim trailing blank lines from preserved content
        preserved=$(echo "$preserved" | awk '
            /[^ \t]/ { p=NR }
            { lines[NR]=$0 }
            END { for (i=1; i<=p; i++) print lines[i] }
        ')

        # Write preserved content + new block
        if [[ -n "$preserved" ]]; then
            {
                echo "$preserved"
                echo ""
                echo "$polaris_block"
            } > "$claude_md_file"
        else
            echo "$polaris_block" > "$claude_md_file"
        fi
        ok "Updated Polaris section in $claude_md_file"
    else
        # No markers — append
        {
            cat "$claude_md_file"
            echo ""
            echo "$polaris_block"
        } > "$claude_md_file"
        ok "Appended Polaris section to $claude_md_file"
    fi
}

# Fresh mode: write defaults template + Polaris block (global only)
_apply_claude_md_fresh() {
    local claude_md_file="$1"
    local polaris_block="$2"
    local dry_run="$3"

    # Warn if existing file has user content
    if [[ -f "$claude_md_file" ]]; then
        local has_user_content
        has_user_content=$(awk '
            /<!-- polaris:start -->/ { skip=1; next }
            /<!-- polaris:end -->/   { skip=0; next }
            !skip && /[^ \t]/ { found=1 }
            END { print found+0 }
        ' "$claude_md_file")

        if [[ "$has_user_content" == "1" ]]; then
            warn "Existing $claude_md_file has content outside Polaris markers"
            warn "Backup saved to ${claude_md_file}.bak"
            if [[ "$dry_run" != "true" ]]; then
                cp "$claude_md_file" "${claude_md_file}.bak"
            fi
        fi
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "  would create: $claude_md_file (fresh with defaults)"
        return 0
    fi

    local defaults_file="$SKILLS_REPO/templates/claude-md-defaults.md"
    {
        if [[ -f "$defaults_file" ]]; then
            cat "$defaults_file"
        else
            warn "Defaults template not found at templates/claude-md-defaults.md"
            echo "# Project"
            echo ""
        fi
        echo ""
        echo "$polaris_block"
    } > "$claude_md_file"
    ok "Created $claude_md_file (fresh with defaults + Polaris skills)"
}

# ---- Commands ----

cmd_global() {
    ensure_init
    local dry_run="$1"
    local force="$2"
    local fresh="$3"
    local no_claude_md="$4"

    info "Installing global skills to $GLOBAL_CLAUDE_DIR/"

    local profile_file="$SKILLS_REPO/profiles/global.txt"
    if [[ ! -f "$profile_file" ]]; then
        err "No global profile found at profiles/global.txt"
        exit 1
    fi

    while IFS= read -r line; do
        _install_line "$line" "$GLOBAL_CLAUDE_DIR" "$dry_run" "$force"
    done < <(read_profile "global")

    # Generate CLAUDE.md
    if [[ "$no_claude_md" != "true" ]]; then
        _update_claude_md "global" "$GLOBAL_CLAUDE_DIR/CLAUDE.md" "~/.claude/" "$fresh" "$dry_run"
    fi

    echo ""
    ok "Global install complete"
}

cmd_project() {
    ensure_init
    local profile="$1"
    local dry_run="$2"
    local force="$3"
    local target="$4"
    local fresh="$5"
    local no_claude_md="$6"
    shift 6
    local extras=("$@")

    if [[ "$fresh" == "true" ]]; then
        warn "--fresh is only supported for 'polaris global'. Ignoring."
        fresh="false"
    fi

    if [[ -z "$profile" ]]; then
        err "Specify a profile: ./install.sh project --profile <name>"
        echo ""
        cmd_list_profiles
        exit 1
    fi

    local project_dir
    if [[ -n "$target" ]]; then
        # Resolve to absolute path
        project_dir="$(cd "$target" 2>/dev/null && pwd || echo "$target")"
        if [[ ! -d "$project_dir" ]]; then
            err "Target directory does not exist: $target"
            exit 1
        fi
    else
        # Find project root (look for .git)
        project_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [[ -z "$project_dir" ]]; then
            err "Not inside a git repo. Run from your project directory or use --target."
            exit 1
        fi
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

    # Generate CLAUDE.md
    if [[ "$no_claude_md" != "true" ]]; then
        _update_claude_md "$profile" "$claude_dir/CLAUDE.md" ".claude/" "$fresh" "$dry_run" "${extras[@]+"${extras[@]}"}"
    fi

    echo ""
    ok "Project install complete ($profile)"
}

cmd_status() {
    ensure_init

    echo ""
    info "Checking global installs ($GLOBAL_CLAUDE_DIR/)..."
    local found_global=false
    for subdir in skills agents workflows templates; do
        if [[ -d "$GLOBAL_CLAUDE_DIR/$subdir" ]]; then
            found_global=true
        fi
    done
    if [[ "$found_global" == "true" ]]; then
        find "$GLOBAL_CLAUDE_DIR/skills" "$GLOBAL_CLAUDE_DIR/agents" "$GLOBAL_CLAUDE_DIR/workflows" "$GLOBAL_CLAUDE_DIR/templates" -type f -name "*.md" 2>/dev/null | while read -r dest; do
            local rel="${dest#$GLOBAL_CLAUDE_DIR/}"
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
        done || true
    else
        echo "  (nothing installed)"
    fi

    # Check global CLAUDE.md
    if [[ -f "$GLOBAL_CLAUDE_DIR/CLAUDE.md" ]]; then
        if grep -q '<!-- polaris:start -->' "$GLOBAL_CLAUDE_DIR/CLAUDE.md"; then
            ok "  CLAUDE.md has Polaris section"
        else
            warn "  CLAUDE.md exists but has no Polaris section (run 'polaris global')"
        fi
    else
        warn "  CLAUDE.md not found (run 'polaris global' to generate)"
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
    local found_project=false
    if [[ -n "$project_dir" ]]; then
        for subdir in skills agents workflows templates; do
            if [[ -d "$project_dir/.claude/$subdir" ]]; then
                found_project=true
            fi
        done
    fi
    if [[ "$found_project" == "true" ]]; then
        echo ""
        info "Checking project installs ($project_dir/.claude/)..."
        find "$project_dir/.claude/skills" "$project_dir/.claude/agents" "$project_dir/.claude/workflows" "$project_dir/.claude/templates" -type f -name "*.md" 2>/dev/null | while read -r dest; do
            local rel="${dest#$project_dir/.claude/}"
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
        done || true

        # Check project CLAUDE.md
        if [[ -f "$project_dir/.claude/CLAUDE.md" ]]; then
            if grep -q '<!-- polaris:start -->' "$project_dir/.claude/CLAUDE.md"; then
                ok "  CLAUDE.md has Polaris section"
            else
                warn "  CLAUDE.md exists but has no Polaris section"
            fi
        else
            warn "  CLAUDE.md not found (run 'polaris project' to generate)"
        fi

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
FRESH="false"
NO_CLAUDE_MD="false"
PROFILE=""
TARGET=""
EXTRAS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile|-p)     PROFILE="$2"; shift 2 ;;
        --target|-t)      TARGET="$2"; shift 2 ;;
        --extra|-e)       EXTRAS+=("$2"); shift 2 ;;
        --dry-run|-n)     DRY_RUN="true"; shift ;;
        --force|-f)       FORCE="true"; shift ;;
        --fresh)          FRESH="true"; shift ;;
        --no-claude-md)   NO_CLAUDE_MD="true"; shift ;;
        *)                err "Unknown option: $1"; usage ;;
    esac
done

case "$COMMAND" in
    init)           cmd_init ;;
    global)         cmd_global "$DRY_RUN" "$FORCE" "$FRESH" "$NO_CLAUDE_MD" ;;
    project)        cmd_project "$PROFILE" "$DRY_RUN" "$FORCE" "$TARGET" "$FRESH" "$NO_CLAUDE_MD" "${EXTRAS[@]+"${EXTRAS[@]}"}" ;;
    status)         cmd_status ;;
    list-profiles)  cmd_list_profiles ;;
    list-skills)    cmd_list_skills ;;
    *)              usage ;;
esac
