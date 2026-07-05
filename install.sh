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
  new <path>            Create a new project with stack context (for brainstorming)
  project               Install skills into a project's .claude/ (interactive stack selection)
  uninstall             Remove Polaris from a project (preserves user content)
  hooks <sub>           Manage optional session hooks (install|status|uninstall)
  status                Show what's installed and if anything is stale
  list-profiles         List available profiles and stacks
  list-skills           List all available skills and agents
  validate              Lint profiles (missing files, dup commands, snippets)

Options:
  --stack, -s NAME      Stack to install (repeatable: --stack django --stack nextjs)
                        Override default directory: --stack django:server
  --profile, -p NAME    Legacy: install a single profile (non-composable)
  --target, -t DIR      Target directory (default: current git root)
  --extra, -e PATH      Additional skill to install (can be repeated)
  --dry-run, -n         Show what would be copied without copying
  --force, -f           Overwrite local modifications
  --fresh               Replace CLAUDE.md with defaults template + skills
  --clean               Remove existing Polaris files before reinstalling
  --standalone          Default stack directories to "." (repo root is the stack)
  --no-claude-md        Skip CLAUDE.md generation

Examples:
  ./install.sh init
  ./install.sh global
  ./install.sh global --fresh
  ./install.sh new ~/prj/my-app                         # create project, select stacks, brainstorm
  ./install.sh new ~/prj/my-app --stack django --stack nextjs
  ./install.sh project                                  # interactive stack selection
  ./install.sh project --stack django --stack nextjs     # non-interactive
  ./install.sh project --stack django:api --stack nextjs:client
  ./install.sh project --stack django --standalone              # standalone repo (dir = ".")
  ./install.sh project --clean --stack django --stack nextjs  # wipe and reinstall
  ./install.sh project --clean --fresh --stack django         # wipe and fresh CLAUDE.md
  ./install.sh project --profile django                  # legacy single-profile mode
  ./install.sh uninstall                                 # remove Polaris from project
  ./install.sh uninstall --target ~/prj/my-app           # remove from specific project
  ./install.sh hooks install                             # install minimal hooks into project
  ./install.sh hooks install --profile minimal --dry-run # preview hook install
  ./install.sh hooks status                              # show hook profile + freshness
  ./install.sh hooks uninstall                           # remove Polaris hooks
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
      "Write",
      "Glob",
      "Grep",
      "Task",
      "Agent",
      "WebFetch",
      "WebSearch",
      "Bash",
      "mcp__axon__axon_query",
      "mcp__axon__axon_context",
      "mcp__axon__axon_impact",
      "mcp__axon__axon_dead_code",
      "mcp__axon__axon_detect_changes",
      "mcp__axon__axon_list_repos",
      "mcp__axon__axon_cypher"
    ]
  },
  "enabledPlugins": {
    "pyright-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
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
            .[0] as $existing | .[1] as $required |
            $existing *
            {
                "permissions": {
                    "allow": ([$existing.permissions.allow // [], $required.permissions.allow] | add | unique)
                },
                "enabledPlugins": (($existing.enabledPlugins // {}) * $required.enabledPlugins),
                "env": (($existing.env // {}) * $required.env)
            }
        ' "$settings_file" <(echo "$REQUIRED_SETTINGS"))

        echo "$merged" > "$settings_file"
        ok "Merged required settings into $settings_file"
    else
        echo "$REQUIRED_SETTINGS" | jq '.' > "$settings_file"
        ok "Created $settings_file with default settings"
    fi

    # Summarize exactly what Polaris asserted (existing keys are preserved;
    # anything not listed here is left untouched)
    info "Polaris asserted into settings.json:"
    jq -r '
        "  permissions.allow (merged, deduped): " + ((.permissions.allow // []) | join(", ")),
        "  enabledPlugins: " + ((.enabledPlugins // {}) | keys | join(", ")),
        "  env: " + ((.env // {}) | to_entries | map(.key + "=" + (.value | tostring)) | join(", "))
    ' <<< "$REQUIRED_SETTINGS"
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
            # Replace the old alias line (temp file keeps this portable across BSD/GNU sed).
            # Escape sed-special chars in the replacement so a repo path containing
            # &, \, or the | delimiter can't corrupt the substitution.
            local tmp esc
            tmp="$(mktemp)"
            esc="$(printf '%s' "$ALIAS_LINE" | sed 's/[\\&|]/\\&/g')"
            sed "s|alias polaris=.*|${esc}|" "$profile" > "$tmp"
            mv "$tmp" "$profile"
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
    local src="$1"       # relative path in repo, e.g. agents/executor.md
    local dest_dir="$2"  # target root, e.g. /path/to/project/.claude
    local dry_run="${3:-false}"
    local force="${4:-false}"

    local dest="$dest_dir/$src"
    _copy_file "$src" "$dest" "$dry_run" "$force"
}

# Copy a native skill directory (skills/<name>/) into the target, preserving
# structure. Each file is copied via _copy_file so checksum/stale detection works.
copy_skill_dir() {
    local name="$1"      # skill dir name, e.g. "django-patterns"
    local dest_dir="$2"  # target root, e.g. /path/to/project/.claude
    local dry_run="${3:-false}"
    local force="${4:-false}"

    local src_dir="$SKILLS_REPO/skills/$name"
    if [[ ! -d "$src_dir" || ! -f "$src_dir/SKILL.md" ]]; then
        err "profile references a missing skill: $name (expected skills/$name/SKILL.md)"
        return 1
    fi

    local f rel
    while IFS= read -r f; do
        rel="${f#"$SKILLS_REPO"/}"
        _copy_file "$rel" "$dest_dir/$rel" "$dry_run" "$force"
    done < <(find "$src_dir" -type f | sort)
}

# Shared copy logic with checksum comparison
_copy_file() {
    local src="$1"
    local dest="$2"
    local dry_run="${3:-false}"
    local force="${4:-false}"

    # Guard against a profile that references a file no longer in the repo —
    # fail with a clear message instead of a raw cp abort mid-install.
    if [[ ! -f "$SKILLS_REPO/$src" ]]; then
        err "profile references a missing file: $src"
        return 1
    fi

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

# Route a profile line to the right copy function.
# A bare name (no slash) is a native skill directory → skills/<name>/.
# A path (e.g. agents/executor.md) is copied preserving its relative path.
_install_line() {
    local line="$1"
    local dest_dir="$2"
    local dry_run="$3"
    local force="$4"

    if [[ "$line" == */* ]]; then
        copy_skill "$line" "$dest_dir" "$dry_run" "$force"
    else
        copy_skill_dir "$line" "$dest_dir" "$dry_run" "$force"
    fi
}

# ---- Manifest tracking ----

MANIFEST_FILE=".polaris-manifest.json"

# Convert profile lines to installed file paths for the manifest.
# Bare skill name → every file in skills/<name>/ (SKILL.md plus any bundled
# supporting files, so drift/uninstall/status track all of them);
# path lines (agents/…) stay as-is.
_profile_lines_to_paths() {
    local line f
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == */* ]]; then
            echo "$line"
        elif [[ -d "$SKILLS_REPO/skills/$line" ]]; then
            while IFS= read -r f; do
                echo "skills/$line/${f#"$SKILLS_REPO/skills/$line/"}"
            done < <(find "$SKILLS_REPO/skills/$line" -type f | sort)
        else
            echo "skills/$line/SKILL.md"
        fi
    done
}

# Write manifest after install
# Args: claude_dir, profile_lines (newline-separated)
# Reads STACK_NAMES and STACK_DIRS globals for stack info
_write_manifest() {
    local claude_dir="$1"
    local profile_lines="$2"
    local dry_run="${3:-false}"

    local manifest="$claude_dir/$MANIFEST_FILE"

    # Compute the new installed-file list (profile lines → paths, plus any
    # context scaffold files present on disk)
    local new_paths=()
    local path
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        new_paths+=("$path")
    done < <(echo "$profile_lines" | _profile_lines_to_paths)

    # Track context scaffold files whenever they exist on disk — whether this
    # run freshly copied them or they survive from a prior install. Gating this
    # on "did this run copy templates" would drop an untouched scaffold from
    # new_paths on a reinstall (context/ already exists, so nothing is
    # re-copied), and the drift loop below would then wrongly delete it as
    # "no longer tracked".
    local ctx_file
    for ctx_file in context/ROUTER.md context/decisions.md context/conventions.md context/patterns/README.md; do
        [[ -f "$claude_dir/$ctx_file" ]] && new_paths+=("$ctx_file")
    done

    # Manifest drift: remove files the previous manifest tracked that are no
    # longer part of this install (a profile entry dropped or renamed). Without
    # this they linger on disk and, being absent from the new manifest, survive
    # a later uninstall too. Never delete populated context files.
    if [[ -f "$manifest" ]]; then
        local old_path
        while IFS= read -r old_path; do
            [[ -z "$old_path" ]] && continue
            local still_present=false p
            for p in "${new_paths[@]+"${new_paths[@]}"}"; do
                [[ "$p" == "$old_path" ]] && { still_present=true; break; }
            done
            [[ "$still_present" == "true" ]] && continue
            local target="$claude_dir/$old_path"
            [[ -f "$target" ]] || continue
            if [[ "$old_path" == context/* ]] && ! _is_pristine_context_file "$claude_dir" "$old_path"; then
                info "  kept (project content): $old_path"
                continue
            fi
            if [[ "$dry_run" == "true" ]]; then
                echo "  would remove (no longer tracked): $old_path"
            else
                rm -f "$target"
                ok "  removed (no longer tracked): $old_path"
            fi
        done < <(_read_manifest_files "$claude_dir")
        # Prune skill directories emptied by drift removal
        if [[ "$dry_run" != "true" && -d "$claude_dir/skills" ]]; then
            find "$claude_dir/skills" -type d -empty -delete 2>/dev/null || true
        fi
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "  would write: $claude_dir/$MANIFEST_FILE"
        return 0
    fi

    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

    # Build stacks JSON object
    local stacks_json="{"
    local first=true
    local i
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            stacks_json+=", "
        fi
        stacks_json+="\"${STACK_NAMES[$i]}\": \"${STACK_DIRS[$i]}\""
    done
    stacks_json+="}"

    # Build files array from the computed new-path list
    local files_json="["
    first=true
    for path in "${new_paths[@]+"${new_paths[@]}"}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            files_json+=", "
        fi
        files_json+="\"$path\""
    done
    files_json+="]"

    cat > "$manifest" <<EOF
{
  "installed_at": "$timestamp",
  "layout": "${REPO_LAYOUT:-monorepo}",
  "stacks": $stacks_json,
  "files": $files_json
}
EOF
    ok "  wrote manifest: $MANIFEST_FILE"
}

# Read file list from manifest
# Args: claude_dir
# Outputs file paths (one per line)
_read_manifest_files() {
    local claude_dir="$1"
    local manifest="$claude_dir/$MANIFEST_FILE"

    if [[ ! -f "$manifest" ]]; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        jq -r '.files[]' "$manifest" 2>/dev/null
    else
        # Fallback: grep for quoted strings in the files array
        sed -n '/\"files\"/,/\]/p' "$manifest" | grep '"' | sed 's/.*"\([^"]*\)".*/\1/' | grep -v '^files$'
    fi
}

# ---- Profile reading ----

# Read a profile file and return the list of files
read_profile() {
    local profile_name="$1"
    local profile_file="$SKILLS_REPO/profiles/${profile_name}.txt"

    if [[ ! -f "$profile_file" ]]; then
        # Diagnostics to stderr and `return` (not `exit`): read_profile runs
        # inside command/process substitutions, where stdout is captured as
        # profile lines and `exit` only kills the subshell.
        err "Profile not found: $profile_name"
        echo "Available profiles:" >&2
        cmd_list_profiles >&2
        return 1
    fi

    # Read non-empty, non-comment lines
    grep -v '^\s*#' "$profile_file" | grep -v '^\s*$'
}

# List selectable profile base names (excludes _-prefixed helpers like
# _multi-stack, and global — that installs via 'polaris global', not --stack)
_available_profile_names() {
    local f b
    for f in "$SKILLS_REPO"/profiles/*.txt; do
        [[ -f "$f" ]] || continue
        b="$(basename "$f" .txt)"
        [[ "$b" == _* || "$b" == "global" ]] && continue
        echo "$b"
    done
}

# Fail loudly if any requested --stack/--profile name has no profiles/<name>.txt.
# Runs before any install work so a bad name can't fall through to read_profile
# inside a subshell (where its diagnostics would be captured and installed as files).
_validate_requested_profiles() {
    local bad=() name
    for name in "$@"; do
        [[ -z "$name" ]] && continue
        if [[ "$name" == "global" ]]; then
            err "'global' is not a stack — run 'polaris global' to install it to ~/.claude/"
            exit 1
        fi
        [[ -f "$SKILLS_REPO/profiles/${name}.txt" ]] || bad+=("$name")
    done
    if [[ ${#bad[@]} -gt 0 ]]; then
        local available
        available="$(_available_profile_names | tr '\n' ' ')"
        for name in "${bad[@]}"; do
            err "Unknown stack '$name' (available: ${available% })"
        done
        exit 1
    fi
}

# ---- Clean / uninstall helpers ----

# Map an installed context file back to its pristine template in the repo
_context_template_for() {
    case "$1" in
        context/ROUTER.md)          echo "templates/context/ROUTER.md" ;;
        context/decisions.md)       echo "templates/context/decisions.md" ;;
        context/conventions.md)     echo "templates/context/conventions.md" ;;
        context/patterns/README.md) echo "templates/context/patterns/README.md" ;;
        *)                          echo "" ;;
    esac
}

# True if an installed context file is still the unmodified template.
# Populated context files (via /intel or /remember) are user content.
_is_pristine_context_file() {
    local claude_dir="$1"
    local rel_path="$2"
    local template
    template="$(_context_template_for "$rel_path")"
    [[ -n "$template" && -f "$SKILLS_REPO/$template" ]] || return 1
    local src_hash dest_hash
    src_hash="$(shasum -a 256 "$SKILLS_REPO/$template" | cut -d' ' -f1)"
    dest_hash="$(shasum -a 256 "$claude_dir/$rel_path" | cut -d' ' -f1)"
    [[ "$src_hash" == "$dest_hash" ]]
}

# Remove Polaris-installed files from a project
# Args: claude_dir, dry_run
_clean_project() {
    local claude_dir="$1"
    local dry_run="${2:-false}"

    info "Cleaning Polaris files from $claude_dir/"

    local manifest="$claude_dir/$MANIFEST_FILE"
    local removed=0

    if [[ -f "$manifest" ]]; then
        # Manifest exists — remove only tracked files
        info "Using manifest to identify Polaris files..."
        while IFS= read -r rel_path; do
            [[ -z "$rel_path" ]] && continue
            local target="$claude_dir/$rel_path"
            if [[ -f "$target" ]]; then
                # Context files that no longer match the pristine templates hold
                # project knowledge — never delete those.
                if [[ "$rel_path" == context/* ]] && ! _is_pristine_context_file "$claude_dir" "$rel_path"; then
                    info "  preserved (project content): $rel_path"
                    continue
                fi
                if [[ "$dry_run" == "true" ]]; then
                    echo "  would remove: $rel_path"
                else
                    rm "$target"
                    echo "  removed: $rel_path"
                fi
                (( removed++ )) || true
            fi
        done < <(_read_manifest_files "$claude_dir")
    else
        # No manifest — remove standard Polaris directories
        warn "No manifest found — removing standard Polaris directories"
        for subdir in skills agents workflows templates; do
            if [[ -d "$claude_dir/$subdir" ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    echo "  would remove: $subdir/"
                else
                    rm -rf "$claude_dir/$subdir"
                    echo "  removed: $subdir/"
                fi
                (( removed++ )) || true
            fi
        done
        # Context scaffold: remove only files still identical to the pristine
        # templates; populated ones hold project knowledge
        if [[ -d "$claude_dir/context" ]]; then
            local ctx
            for ctx in context/ROUTER.md context/decisions.md context/conventions.md context/patterns/README.md; do
                if [[ -f "$claude_dir/$ctx" ]] && _is_pristine_context_file "$claude_dir" "$ctx"; then
                    if [[ "$dry_run" == "true" ]]; then
                        echo "  would remove: $ctx"
                    else
                        rm "$claude_dir/$ctx"
                        echo "  removed: $ctx"
                    fi
                    (( removed++ )) || true
                fi
            done
            if find "$claude_dir/context" -type f 2>/dev/null | grep -q .; then
                warn "Kept context/ files with project content — delete manually if unwanted"
            fi
        fi
        # Commands can't be told apart from user-authored ones without a
        # manifest — never blow the whole directory away. Warn and keep it.
        if [[ -d "$claude_dir/commands" ]]; then
            warn "Kept commands/ — can't distinguish Polaris commands from yours without a manifest; remove manually if unwanted"
        fi
    fi

    # Back up CLAUDE.md if it has user content
    local claude_md="$claude_dir/CLAUDE.md"
    if [[ -f "$claude_md" ]]; then
        local has_user_content
        has_user_content=$(awk '
            /<!-- polaris:start -->/ { skip=1; next }
            /<!-- polaris:end -->/   { skip=0; next }
            !skip && /[^ \t]/ { found=1 }
            END { print found+0 }
        ' "$claude_md")

        if [[ "$has_user_content" == "1" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo "  would back up: CLAUDE.md → CLAUDE.md.bak"
            else
                cp "$claude_md" "${claude_md}.bak"
                warn "Backed up CLAUDE.md → CLAUDE.md.bak (has user content)"
            fi
        fi

        # Strip Polaris block from CLAUDE.md
        if grep -q '<!-- polaris:start -->' "$claude_md"; then
            if [[ "$dry_run" == "true" ]]; then
                echo "  would strip: Polaris section from CLAUDE.md"
            else
                local preserved
                preserved=$(awk '
                    /<!-- polaris:start -->/ { skip=1; next }
                    /<!-- polaris:end -->/   { skip=0; next }
                    !skip { print }
                ' "$claude_md")

                # Trim trailing blank lines
                preserved=$(printf '%s\n' "$preserved" | awk '
                    /[^ \t]/ { p=NR }
                    { lines[NR]=$0 }
                    END { for (i=1; i<=p; i++) print lines[i] }
                ')

                if [[ -n "$preserved" ]]; then
                    printf '%s\n' "$preserved" > "$claude_md"
                    ok "Stripped Polaris section from CLAUDE.md (user content preserved)"
                else
                    rm "$claude_md"
                    ok "Removed CLAUDE.md (was only Polaris content)"
                fi
            fi
        fi
    fi

    # Remove manifest
    if [[ -f "$manifest" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "  would remove: $MANIFEST_FILE"
        else
            rm "$manifest"
            echo "  removed: $MANIFEST_FILE"
        fi
    fi

    # Clean up empty directories
    if [[ "$dry_run" != "true" ]]; then
        for subdir in skills agents workflows templates commands context; do
            if [[ -d "$claude_dir/$subdir" ]]; then
                find "$claude_dir/$subdir" -type d -empty -delete 2>/dev/null || true
            fi
        done
    fi

    ok "Clean complete ($removed items removed)"
    echo ""
}

# ---- Stack composition helpers ----

# Parse metadata headers from a profile file
# Sets global vars: _STACK_TYPE, _STACK_LABEL, _STACK_DIRECTORY
_read_profile_metadata() {
    local profile_file="$1"
    _STACK_TYPE=""
    _STACK_LABEL=""
    _STACK_DIRECTORY=""

    while IFS= read -r line; do
        case "$line" in
            "# stack: "*)     _STACK_TYPE="${line#\# stack: }" ;;
            "# label: "*)     _STACK_LABEL="${line#\# label: }" ;;
            "# directory: "*) _STACK_DIRECTORY="${line#\# directory: }" ;;
            "#"*)             ;; # other comments
            *)                break ;; # stop at first non-comment line
        esac
    done < "$profile_file"
}

# Discover stack profiles by category (backend or frontend)
# Outputs: profile names (one per line)
_discover_stacks() {
    local category="$1"

    for f in "$SKILLS_REPO"/profiles/*.txt; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == _* ]] && continue
        _read_profile_metadata "$f"
        if [[ "$_STACK_TYPE" == "$category" ]]; then
            basename "$f" .txt
        fi
    done
}

# Set a stack's directory in the parallel arrays
_set_stack_dir() {
    local name="$1"
    local dir="$2"
    local i
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        if [[ "${STACK_NAMES[$i]}" == "$name" ]]; then
            STACK_DIRS[$i]="$dir"
            return
        fi
    done
    # Not found — append
    STACK_NAMES+=("$name")
    STACK_DIRS+=("$dir")
}

# Interactive stack selection
# Populates STACK_NAMES and STACK_DIRS arrays
_interactive_select() {
    echo ""
    echo -e "${BLUE}Polaris — Project Setup${NC}"
    echo ""

    # Discover available stacks
    local backends=()
    local backend_labels=()
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        backends+=("$name")
        _read_profile_metadata "$SKILLS_REPO/profiles/${name}.txt"
        backend_labels+=("$_STACK_LABEL")
    done < <(_discover_stacks "backend")

    local frontends=()
    local frontend_labels=()
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        frontends+=("$name")
        _read_profile_metadata "$SKILLS_REPO/profiles/${name}.txt"
        frontend_labels+=("$_STACK_LABEL")
    done < <(_discover_stacks "frontend")

    # Select backend
    if [[ ${#backends[@]} -gt 0 ]]; then
        echo "Select a backend (enter number, or s to skip):"
        local i
        for (( i=0; i<${#backends[@]}; i++ )); do
            echo "  $((i+1))) ${backend_labels[$i]}"
        done
        echo "  s) Skip"
        echo ""
        local choice
        read -rp "> " choice
        if [[ "$choice" != "s" && "$choice" != "S" && -n "$choice" ]]; then
            local idx=$((choice - 1))
            if [[ $idx -ge 0 && $idx -lt ${#backends[@]} ]]; then
                local bname="${backends[$idx]}"
                _read_profile_metadata "$SKILLS_REPO/profiles/${bname}.txt"
                local _dir="$_STACK_DIRECTORY"
                [[ "$STANDALONE" == "true" ]] && _dir="."
                _set_stack_dir "$bname" "$_dir"
            else
                err "Invalid selection"
                exit 1
            fi
        fi
        echo ""
    fi

    # Select frontend(s)
    if [[ ${#frontends[@]} -gt 0 ]]; then
        echo "Select frontend(s) (space-separated numbers, or s to skip):"
        local i
        for (( i=0; i<${#frontends[@]}; i++ )); do
            echo "  $((i+1))) ${frontend_labels[$i]}"
        done
        echo "  s) Skip"
        echo ""
        local choices
        read -rp "> " choices
        if [[ "$choices" != "s" && "$choices" != "S" && -n "$choices" ]]; then
            for choice in $choices; do
                local idx=$((choice - 1))
                if [[ $idx -ge 0 && $idx -lt ${#frontends[@]} ]]; then
                    local fname="${frontends[$idx]}"
                    _read_profile_metadata "$SKILLS_REPO/profiles/${fname}.txt"
                    local _dir="$_STACK_DIRECTORY"
                    [[ "$STANDALONE" == "true" ]] && _dir="."
                    _set_stack_dir "$fname" "$_dir"
                else
                    warn "Skipping invalid selection: $choice"
                fi
            done
        fi
        echo ""
    fi

    # Must have at least one stack
    if [[ ${#STACK_NAMES[@]} -eq 0 ]]; then
        err "No stacks selected. Use --profile for non-stack profiles."
        exit 1
    fi

    # Prompt for directory overrides
    local i
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        local name="${STACK_NAMES[$i]}"
        local default_dir="${STACK_DIRS[$i]}"
        _read_profile_metadata "$SKILLS_REPO/profiles/${name}.txt"
        local label="$_STACK_LABEL"
        local dir
        read -rp "Directory for ${label} [${default_dir}]: " dir
        if [[ -n "$dir" ]]; then
            STACK_DIRS[$i]="$dir"
        fi
    done
    echo ""

    # Confirmation
    echo "Will install:"
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        local name="${STACK_NAMES[$i]}"
        _read_profile_metadata "$SKILLS_REPO/profiles/${name}.txt"
        local category="$_STACK_TYPE"
        local label="$_STACK_LABEL"
        local dir="${STACK_DIRS[$i]}"
        local cap_category
        cap_category="$(printf '%s' "${category:0:1}" | tr '[:lower:]' '[:upper:]')${category:1}"
        echo "  ${cap_category}: ${label} → ${dir}/"
    done
    echo ""

    local confirm
    read -rp "Proceed? [Y/n] " confirm
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        echo "Cancelled."
        exit 0
    fi
}

# Merge multiple stack profiles into deduplicated lines
# Output: one profile line per line (bare skill names, agents/… paths, etc.)
_merge_profiles() {
    # Args: stack names
    # Deduplicate by line. Under native skills a name IS its content, so a
    # repeated name is just a duplicate to drop — the Phase 9 cmd-name conflict
    # guard is retired: two stacks can no longer bind the same command name to
    # different files (each bootstrap/skill is its own uniquely-named dir).
    local stacks=("$@")
    local seen_keys=()
    local merged_lines=()
    local stack line k found

    for stack in "${stacks[@]}"; do
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            found=false
            for k in "${seen_keys[@]+"${seen_keys[@]}"}"; do
                [[ "$k" == "$line" ]] && { found=true; break; }
            done
            if [[ "$found" == "false" ]]; then
                seen_keys+=("$line")
                merged_lines+=("$line")
            fi
        done < <(read_profile "$stack")
    done

    if [[ ${#stacks[@]} -gt 1 ]] && [[ -f "$SKILLS_REPO/profiles/_multi-stack.txt" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            found=false
            for k in "${seen_keys[@]+"${seen_keys[@]}"}"; do
                [[ "$k" == "$line" ]] && { found=true; break; }
            done
            if [[ "$found" == "false" ]]; then
                seen_keys+=("$line")
                merged_lines+=("$line")
            fi
        done < <(read_profile "_multi-stack")
    fi

    printf '%s\n' "${merged_lines[@]}"
}

# Detect if project uses monorepo or multi-repo layout
# Sets global REPO_LAYOUT to "monorepo" or "multi-repo"
_detect_repo_layout() {
    local project_dir="$1"
    REPO_LAYOUT="monorepo"

    # If project root is a git repo, it's a monorepo
    if [[ -d "$project_dir/.git" ]]; then
        return
    fi

    # Check if any stack directory is its own git repo
    local i
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        local dir="${STACK_DIRS[$i]}"
        if [[ -n "$dir" && -d "$project_dir/$dir/.git" ]]; then
            REPO_LAYOUT="multi-repo"
            return
        fi
    done
}

# Generate stack context markdown from .claude.md snippets
_generate_stack_context() {
    local output=""

    # Add multi-repo notice if applicable
    if [[ "$REPO_LAYOUT" == "multi-repo" ]]; then
        output+="> **Repo layout: multi-repo** — each stack directory below is its own git repository."$'\n'
        output+="> Always \`cd\` into the appropriate directory before running git commands."$'\n'
        output+="> Never have a single phase span multiple repos. Use integration summaries as handoffs."$'\n\n'
    fi

    local i
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        local name="${STACK_NAMES[$i]}"
        local dir="${STACK_DIRS[$i]}"
        local snippet="$SKILLS_REPO/profiles/${name}.claude.md"
        if [[ -f "$snippet" ]]; then
            local content
            content="$(cat "$snippet")"
            content="${content//\{directory\}/$dir}"
            output+="$content"$'\n\n'
        fi
    done
    echo "$output"
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

# Categorize a list of lines into skills/agents/workflows/templates/commands arrays
# Reads from stdin, populates global arrays: _BLK_SKILLS, _BLK_AGENTS, etc.
_categorize_lines() {
    _BLK_AGENTS=()
    _BLK_COMMANDS=()

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == agents/* ]]; then
            _BLK_AGENTS+=("$line")
        elif [[ "$line" != */* ]]; then
            # Bare skill name. Auto-triggering skills need no pointer (native
            # discovery surfaces them); only list command-only skills so users
            # know which slash commands exist.
            if grep -q '^disable-model-invocation: true' "$SKILLS_REPO/skills/$line/SKILL.md" 2>/dev/null; then
                _BLK_COMMANDS+=("$line")
            fi
        fi
    done
}

# Emit the formatted polaris block content (between markers)
# Args: descriptor, path_note, stack_context (optional)
_emit_polaris_block() {
    local descriptor="$1"
    local path_note="$2"
    local stack_context="${3:-}"

    echo "<!-- polaris:start -->"
    echo "## Polaris"
    echo ""
    echo "> Auto-generated by Polaris (${descriptor}). Do not edit between these markers."
    echo ""
    echo "Polaris skills are installed under \`${path_note}skills/\` and discovered automatically — Claude loads a skill when its description or file scope matches the task, so you don't need to reference them by hand."

    if [[ -n "$stack_context" ]]; then
        echo ""
        echo "### Project Structure"
        echo ""
        echo "$stack_context"
    fi

    if [[ ${#_BLK_AGENTS[@]} -gt 0 ]]; then
        echo ""
        echo "### Agents"
        echo ""
        for a in "${_BLK_AGENTS[@]}"; do
            local title
            title="$(_extract_title "$a")"
            echo "- \`${a}\` — ${title}"
        done
    fi

    if [[ ${#_BLK_COMMANDS[@]} -gt 0 ]]; then
        echo ""
        echo "### Command-only skills"
        echo ""
        echo "These do not auto-trigger — invoke them explicitly as slash commands:"
        for c in "${_BLK_COMMANDS[@]}"; do
            echo "- \`/${c}\`"
        done
    fi

    echo "<!-- polaris:end -->"
}

# Generate the marker-wrapped Polaris skills block from a single profile
# Args: profile_name, path_note (e.g. "~/.claude/"), [extra1, extra2, ...]
_generate_polaris_block() {
    local profile_name="$1"
    local path_note="$2"
    shift 2
    local extras=("$@")

    # Collect all lines (process substitution keeps _categorize_lines in current shell)
    _categorize_lines < <(
        read_profile "$profile_name"
        for extra in "${extras[@]+"${extras[@]}"}"; do
            echo "$extra"
        done
    )

    _emit_polaris_block "profile: ${profile_name}" "$path_note"
}

# Generate the marker-wrapped Polaris skills block from merged stack lines
# Args: descriptor (e.g. "stacks: django + nextjs"), path_note, stack_context, merged_lines
_generate_polaris_block_from_lines() {
    local descriptor="$1"
    local path_note="$2"
    local stack_context="$3"
    local merged_lines="$4"

    _categorize_lines <<< "$merged_lines"

    _emit_polaris_block "$descriptor" "$path_note" "$stack_context"
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
        preserved=$(printf '%s\n' "$preserved" | awk '
            /[^ \t]/ { p=NR }
            { lines[NR]=$0 }
            END { for (i=1; i<=p; i++) print lines[i] }
        ')

        # Write preserved content + new block
        if [[ -n "$preserved" ]]; then
            {
                printf '%s\n' "$preserved"
                echo ""
                echo "$polaris_block"
            } > "$claude_md_file"
        else
            echo "$polaris_block" > "$claude_md_file"
        fi
        ok "Updated Polaris section in $claude_md_file"
    else
        # No markers — append (use temp file to avoid read+write on same file)
        local tmp
        tmp="$(mktemp)"
        {
            cat "$claude_md_file"
            echo ""
            echo "$polaris_block"
        } > "$tmp"
        mv "$tmp" "$claude_md_file"
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

# Resolve project directory from --target or git root
_resolve_project_dir() {
    local target="$1"
    if [[ -n "$target" ]]; then
        local resolved
        resolved="$(cd "$target" 2>/dev/null && pwd || echo "$target")"
        if [[ ! -d "$resolved" ]]; then
            err "Target directory does not exist: $target"
            exit 1
        fi
        echo "$resolved"
    else
        local git_root
        git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [[ -z "$git_root" ]]; then
            warn "Not inside a git repo — using current directory as project root." >&2
            echo "$(pwd)"
        else
            echo "$git_root"
        fi
    fi
}

# Install extras into a claude dir
_install_extras() {
    local claude_dir="$1"
    local dry_run="$2"
    local force="$3"
    shift 3
    local extras=("$@")

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
}

# Install stacks (composable mode)
# Copy context scaffold templates into .claude/context/
# Only copies if .claude/context/ doesn't already exist (preserves user content)
_install_context_templates() {
    local claude_dir="$1"
    local dry_run="${2:-false}"
    local context_dir="$claude_dir/context"
    local template_dir="$SKILLS_REPO/templates/context"

    if [[ -d "$context_dir" ]]; then
        info "  context/ already exists — skipping template copy (preserving user content)"
        # Check for migration opportunity
        if [[ -f "$claude_dir/architecture.md" && ! -f "$context_dir/ROUTER.md" ]]; then
            warn "  Found architecture.md but no context scaffold — run /intel --full to migrate"
        fi
        return 0
    fi

    if [[ ! -d "$template_dir" ]]; then
        warn "  Context templates not found in repo — skipping"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "  would copy: templates/context/ → $context_dir/"
        return 0
    fi

    mkdir -p "$context_dir/patterns"
    cp "$template_dir/ROUTER.md" "$context_dir/ROUTER.md"
    cp "$template_dir/decisions.md" "$context_dir/decisions.md"
    cp "$template_dir/conventions.md" "$context_dir/conventions.md"
    cp "$template_dir/patterns/README.md" "$context_dir/patterns/README.md"
    ok "  copied context scaffold templates to context/"
    info "  Run /intel to populate with project-specific content"
}

_install_stacks() {
    local claude_dir="$1"
    local dry_run="$2"
    local force="$3"
    local no_claude_md="$4"
    local fresh="$5"
    shift 5
    local extras=("$@")

    # Build descriptor
    local descriptor="stacks:"
    local i
    for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
        if [[ $i -gt 0 ]]; then
            descriptor+=" +"
        fi
        descriptor+=" ${STACK_NAMES[$i]}"
    done

    info "Installing ${descriptor} to $claude_dir/"

    # Merge profiles and install
    local merged
    merged="$(_merge_profiles "${STACK_NAMES[@]}")"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        _install_line "$line" "$claude_dir" "$dry_run" "$force"
    done <<< "$merged"

    # Install extras
    _install_extras "$claude_dir" "$dry_run" "$force" "${extras[@]+"${extras[@]}"}"

    # Install context scaffold templates (only if context/ doesn't exist yet)
    _install_context_templates "$claude_dir" "$dry_run"

    # Detect repo layout (monorepo vs multi-repo)
    local project_dir
    project_dir="$(dirname "$claude_dir")"
    _detect_repo_layout "$project_dir"

    # Generate CLAUDE.md
    if [[ "$no_claude_md" != "true" ]]; then
        local stack_context
        stack_context="$(_generate_stack_context)"

        local polaris_block
        polaris_block="$(_generate_polaris_block_from_lines "$descriptor" ".claude/" "$stack_context" "$merged")"

        echo ""
        info "Updating CLAUDE.md..."
        if [[ "$fresh" == "true" ]]; then
            _apply_claude_md_fresh "$claude_dir/CLAUDE.md" "$polaris_block" "$dry_run"
        else
            _apply_claude_md_amend "$claude_dir/CLAUDE.md" "$polaris_block" "$dry_run"
        fi
    fi

    # Write manifest
    _write_manifest "$claude_dir" "$merged" "$dry_run"

    echo ""
    ok "Project install complete (${descriptor})"
}

# Install a single profile (legacy mode)
_install_single_profile() {
    local profile="$1"
    local claude_dir="$2"
    local dry_run="$3"
    local force="$4"
    local no_claude_md="$5"
    shift 5
    local extras=("$@")

    info "Installing profile '$profile' to $claude_dir/"

    local profile_lines
    profile_lines="$(read_profile "$profile")"

    while IFS= read -r line; do
        _install_line "$line" "$claude_dir" "$dry_run" "$force"
    done <<< "$profile_lines"

    # Install extras
    _install_extras "$claude_dir" "$dry_run" "$force" "${extras[@]+"${extras[@]}"}"

    # Install context scaffold templates (only if context/ doesn't exist yet)
    _install_context_templates "$claude_dir" "$dry_run"

    # Generate CLAUDE.md
    if [[ "$no_claude_md" != "true" ]]; then
        _update_claude_md "$profile" "$claude_dir/CLAUDE.md" ".claude/" "false" "$dry_run" "${extras[@]+"${extras[@]}"}"
    fi

    # Write manifest
    _write_manifest "$claude_dir" "$profile_lines" "$dry_run"

    echo ""
    ok "Project install complete ($profile)"
}

cmd_new() {
    ensure_init
    local project_path="$1"
    local dry_run="$2"
    local force="$3"
    local no_claude_md="$4"
    local fresh="$5"
    shift 5
    local extras=("$@")

    if [[ -z "$project_path" ]]; then
        err "Usage: polaris new <path>"
        err "Example: polaris new ~/prj/my-app"
        exit 1
    fi

    # Validate any requested stack names before creating anything
    _validate_requested_profiles "${STACK_NAMES[@]+"${STACK_NAMES[@]}"}"

    # Resolve to absolute path
    if [[ "$project_path" != /* ]]; then
        project_path="$(pwd)/$project_path"
    fi

    echo ""
    echo -e "${BLUE}Polaris — New Project${NC}"
    echo ""

    # Create directory
    if [[ -d "$project_path" ]]; then
        warn "Directory already exists: $project_path"
        # Check if it's empty (aside from hidden files like .git)
        local file_count
        file_count="$(find "$project_path" -maxdepth 1 -not -name '.*' -not -path "$project_path" | wc -l | tr -d ' ')"
        if [[ "$file_count" -gt 0 ]]; then
            warn "Directory is not empty — proceeding anyway"
        fi
    else
        if [[ "$dry_run" == "true" ]]; then
            echo "  would create: $project_path"
        else
            mkdir -p "$project_path"
            ok "Created $project_path"
        fi
    fi

    # Git init
    if [[ -d "$project_path/.git" ]]; then
        ok "Already a git repo"
    elif [[ "$dry_run" == "true" ]]; then
        echo "  would run: git init in $project_path"
    else
        git -C "$project_path" init -q
        ok "Initialized git repo"
    fi

    # Stack selection — interactive if no --stack flags given
    if [[ ${#STACK_NAMES[@]} -eq 0 ]]; then
        _interactive_select
    else
        # Fill in default dirs for stacks without overrides
        local i
        for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
            if [[ -z "${STACK_DIRS[$i]}" ]]; then
                if [[ "$STANDALONE" == "true" ]]; then
                    STACK_DIRS[$i]="."
                else
                    _read_profile_metadata "$SKILLS_REPO/profiles/${STACK_NAMES[$i]}.txt"
                    STACK_DIRS[$i]="$_STACK_DIRECTORY"
                fi
            fi
        done
    fi

    # Create docs/design/ for design artifacts
    if [[ "$dry_run" == "true" ]]; then
        echo "  would create: $project_path/docs/design/"
    else
        mkdir -p "$project_path/docs/design"
        ok "Created docs/design/ (drop wireframes, briefs, and flow diagrams here)"
    fi

    # Install stacks into project
    local claude_dir="$project_path/.claude"
    [[ "$dry_run" == "true" ]] || mkdir -p "$claude_dir"
    _install_stacks "$claude_dir" "$dry_run" "$force" "$no_claude_md" "$fresh" "${extras[@]+"${extras[@]}"}"

    echo ""
    ok "Project ready at $project_path"
    echo ""
    info "Next steps:"
    echo "  cd $project_path"
    echo ""
    echo "  Option A — brainstorm from scratch:"
    echo "    Open Claude Code and brainstorm your idea"
    echo ""
    echo "  Option B — bring existing design work:"
    echo "    Drop briefs, wireframes, sitemaps into docs/design/"
    echo "    Then open Claude Code and use the design-intake agent"
}

cmd_project() {
    ensure_init
    local profile="$1"
    local dry_run="$2"
    local force="$3"
    local target="$4"
    local fresh="$5"
    local no_claude_md="$6"
    local clean="$7"
    shift 7
    local extras=("$@")

    # Validate: can't use both --profile and --stack
    if [[ -n "$profile" && ${#STACK_NAMES[@]} -gt 0 ]]; then
        err "Cannot use --profile and --stack together."
        err "Use --stack for composable installs or --profile for legacy single-profile mode."
        exit 1
    fi

    # Validate every requested stack/profile name before any install work
    _validate_requested_profiles "$profile" "${STACK_NAMES[@]+"${STACK_NAMES[@]}"}"

    local project_dir
    project_dir="$(_resolve_project_dir "$target")"
    local claude_dir="$project_dir/.claude"
    [[ "$dry_run" == "true" ]] || mkdir -p "$claude_dir"

    # Clean existing Polaris files if requested
    if [[ "$clean" == "true" ]]; then
        _clean_project "$claude_dir" "$dry_run"
        # After clean, force-install everything (no skip on unchanged)
        force="true"
    fi

    if [[ -n "$profile" ]]; then
        # Legacy: single profile mode
        _install_single_profile "$profile" "$claude_dir" "$dry_run" "$force" "$no_claude_md" "${extras[@]+"${extras[@]}"}"
    elif [[ ${#STACK_NAMES[@]} -gt 0 ]]; then
        # Non-interactive stack mode — fill in default dirs for stacks without overrides
        local i
        for (( i=0; i<${#STACK_NAMES[@]}; i++ )); do
            if [[ -z "${STACK_DIRS[$i]}" ]]; then
                if [[ "$STANDALONE" == "true" ]]; then
                    STACK_DIRS[$i]="."
                else
                    _read_profile_metadata "$SKILLS_REPO/profiles/${STACK_NAMES[$i]}.txt"
                    STACK_DIRS[$i]="$_STACK_DIRECTORY"
                fi
            fi
        done
        _install_stacks "$claude_dir" "$dry_run" "$force" "$no_claude_md" "$fresh" "${extras[@]+"${extras[@]}"}"
    else
        # Interactive mode
        _interactive_select
        _install_stacks "$claude_dir" "$dry_run" "$force" "$no_claude_md" "$fresh" "${extras[@]+"${extras[@]}"}"
    fi
}

cmd_uninstall() {
    ensure_init
    local dry_run="$1"
    local target="$2"

    local project_dir
    project_dir="$(_resolve_project_dir "$target")"
    local claude_dir="$project_dir/.claude"

    if [[ ! -d "$claude_dir" ]]; then
        err "No .claude/ directory found in $project_dir"
        exit 1
    fi

    echo ""
    _clean_project "$claude_dir" "$dry_run"
    ok "Polaris uninstalled from $project_dir"
    echo ""
}

# ---- Hooks (optional session guardrails) ----
#
# Hooks are the one place Polaris ships executable code instead of markdown.
# They are opt-in (never installed by 'global' or 'project'), project-scoped,
# and written as POSIX-friendly shell so the repo keeps a single runtime.

HOOK_SCRIPTS=(
    "polaris-session-start.sh"
    "polaris-edited-file-accumulator.sh"
    "polaris-stop-summary.sh"
)

# Strip any existing Polaris hook groups, then append the profile's hooks.
# Idempotent: re-running install never duplicates entries. User hooks and
# other settings keys are preserved.
_HOOKS_MERGE_FILTER='
  def strip(a): [ (a // [])[] | select( ([.hooks[]?.command] | map(test("polaris-")) | any) | not ) ];
  .[0] as $existing | .[1] as $new |
  ($existing + {hooks: ($existing.hooks // {})})
  | reduce ($new.hooks | keys[]) as $evt (.;
      .hooks[$evt] = ( strip(.hooks[$evt]) + $new.hooks[$evt] )
    )
'

# Remove Polaris hook groups, drop emptied event arrays, and drop an empty
# hooks object. Leaves user hooks and other settings untouched.
_HOOKS_STRIP_FILTER='
  def strip(a): [ (a // [])[] | select( ([.hooks[]?.command] | map(test("polaris-")) | any) | not ) ];
  if (.hooks | type) == "object"
  then .hooks |= ( with_entries(.value |= strip(.)) | with_entries(select(.value | length > 0)) )
       | (if (.hooks | length) == 0 then del(.hooks) else . end)
  else . end
'

# Record installed hooks under the manifest's "hooks" key
_hooks_write_manifest() {
    local claude_dir="$1"
    local profile="$2"
    local manifest="$claude_dir/$MANIFEST_FILE"
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

    local files_json='['
    local first=true s
    for s in "${HOOK_SCRIPTS[@]}"; do
        if [[ "$first" == "true" ]]; then first=false; else files_json+=', '; fi
        files_json+="\"hooks/$s\""
    done
    files_json+=']'

    local hooks_obj
    hooks_obj="$(jq -n --arg p "$profile" --arg t "$timestamp" --argjson f "$files_json" \
        '{profile:$p, installed_at:$t, files:$f}')"

    if [[ -f "$manifest" ]]; then
        local patched
        patched="$(jq --argjson h "$hooks_obj" '.hooks = $h' "$manifest")"
        printf '%s\n' "$patched" > "$manifest"
    else
        jq -n --argjson h "$hooks_obj" '{hooks:$h}' > "$manifest"
    fi
    ok "  recorded hooks in $MANIFEST_FILE"
}

_hooks_install() {
    local claude_dir="$1"
    local profile="$2"
    local dry_run="$3"
    local force="$4"

    local fragment="$SCRIPT_DIR/hooks/${profile}.json"
    if [[ ! -f "$fragment" ]]; then
        err "Unknown hook profile: $profile (available: minimal)"
        exit 1
    fi

    local settings_file="$claude_dir/settings.json"
    local hooks_dir="$claude_dir/hooks"

    info "Installing '$profile' hooks into $claude_dir/"

    if [[ "$dry_run" == "true" ]]; then
        echo "  would copy scripts to: $hooks_dir/"
        for s in "${HOOK_SCRIPTS[@]}"; do echo "    hooks/$s"; done
        echo "  would merge hook profile '$profile' into: $settings_file"
        echo "  would record hooks in: $claude_dir/$MANIFEST_FILE"
        return 0
    fi

    mkdir -p "$hooks_dir"
    for s in "${HOOK_SCRIPTS[@]}"; do
        cp "$SCRIPT_DIR/hooks/scripts/$s" "$hooks_dir/$s"
        chmod +x "$hooks_dir/$s"
        ok "  installed hook: hooks/$s"
    done

    if [[ -f "$settings_file" ]]; then
        local merged
        merged="$(jq -s "$_HOOKS_MERGE_FILTER" "$settings_file" "$fragment")"
        printf '%s\n' "$merged" > "$settings_file"
        ok "  merged hooks into settings.json"
    else
        jq '.' "$fragment" > "$settings_file"
        ok "  created settings.json with hooks"
    fi

    _hooks_write_manifest "$claude_dir" "$profile"

    ok "Hooks installed. Start a new Claude Code session to load them."
}

_hooks_uninstall() {
    local claude_dir="$1"
    local dry_run="$2"
    local settings_file="$claude_dir/settings.json"
    local hooks_dir="$claude_dir/hooks"

    info "Removing Polaris hooks from $claude_dir/"

    if [[ "$dry_run" == "true" ]]; then
        echo "  would strip Polaris hooks from: $settings_file"
        for s in "${HOOK_SCRIPTS[@]}"; do
            [[ -f "$hooks_dir/$s" ]] && echo "  would remove: hooks/$s"
        done
        echo "  would clear hooks entry in manifest"
        return 0
    fi

    if [[ -f "$settings_file" ]]; then
        local stripped
        stripped="$(jq "$_HOOKS_STRIP_FILTER" "$settings_file")"
        printf '%s\n' "$stripped" > "$settings_file"
        ok "  stripped Polaris hooks from settings.json"
    fi

    for s in "${HOOK_SCRIPTS[@]}"; do
        if [[ -f "$hooks_dir/$s" ]]; then
            rm -f "$hooks_dir/$s"
            ok "  removed hooks/$s"
        fi
    done
    rmdir "$hooks_dir" 2>/dev/null && info "  removed empty hooks/ dir" || true

    local manifest="$claude_dir/$MANIFEST_FILE"
    if [[ -f "$manifest" ]]; then
        local patched
        patched="$(jq 'del(.hooks)' "$manifest")"
        printf '%s\n' "$patched" > "$manifest"
    fi

    ok "Hooks removed. Start a new Claude Code session to apply."
}

_hooks_status() {
    local claude_dir="$1"
    local settings_file="$claude_dir/settings.json"
    local hooks_dir="$claude_dir/hooks"
    local manifest="$claude_dir/$MANIFEST_FILE"

    info "Hooks status for $claude_dir/"

    local profile=""
    if [[ -f "$manifest" ]]; then
        profile="$(jq -r '.hooks.profile // empty' "$manifest" 2>/dev/null || true)"
    fi
    if [[ -n "$profile" ]]; then
        ok "  profile: $profile"
    else
        warn "  no Polaris hooks recorded in manifest"
    fi

    if [[ -f "$settings_file" ]]; then
        local count
        count="$(jq '[.. | objects | .command? // empty | select(test("polaris-"))] | length' "$settings_file" 2>/dev/null || echo 0)"
        if [[ "$count" -gt 0 ]]; then
            ok "  settings.json: $count Polaris hook(s) wired"
        else
            warn "  settings.json: no Polaris hooks wired"
        fi
    else
        warn "  settings.json not found"
    fi

    local s dest src sh dh
    for s in "${HOOK_SCRIPTS[@]}"; do
        dest="$hooks_dir/$s"
        src="$SCRIPT_DIR/hooks/scripts/$s"
        if [[ -f "$dest" ]]; then
            sh="$(shasum -a 256 "$src" | cut -d' ' -f1)"
            dh="$(shasum -a 256 "$dest" | cut -d' ' -f1)"
            if [[ "$sh" == "$dh" ]]; then
                ok "  current: hooks/$s"
            else
                warn "  stale:   hooks/$s (run 'polaris hooks install' to update)"
            fi
        else
            warn "  missing: hooks/$s"
        fi
    done
}

cmd_hooks() {
    local subcmd="$1"
    local profile="$2"
    local target="$3"
    local dry_run="$4"
    local force="$5"

    ensure_init

    if ! command -v jq &>/dev/null; then
        err "Polaris hooks require jq for safe settings.json editing."
        err "Install with: brew install jq"
        exit 1
    fi

    [[ -z "$profile" ]] && profile="minimal"

    local project_dir
    project_dir="$(_resolve_project_dir "$target")"
    local claude_dir="$project_dir/.claude"

    case "$subcmd" in
        install)   mkdir -p "$claude_dir"; _hooks_install "$claude_dir" "$profile" "$dry_run" "$force" ;;
        uninstall) _hooks_uninstall "$claude_dir" "$dry_run" ;;
        status)    _hooks_status "$claude_dir" ;;
        ""|help)   echo "Usage: polaris hooks <install|status|uninstall> [--profile minimal] [--target DIR] [--dry-run]" ;;
        *)         err "Unknown hooks subcommand: $subcmd"
                   echo "Usage: polaris hooks <install|status|uninstall> [--profile minimal]"
                   exit 1 ;;
    esac
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
    info "Available stacks (composable with --stack):"
    for f in "$SCRIPT_DIR"/profiles/*.txt; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == _* ]] && continue
        local name
        name="$(basename "$f" .txt)"
        local count
        count="$(grep -cv '^\s*#\|^\s*$' "$f" 2>/dev/null || echo 0)"
        _read_profile_metadata "$f"
        if [[ -n "$_STACK_TYPE" ]]; then
            echo "  $name ($count files) [$_STACK_TYPE: $_STACK_LABEL]"
        else
            echo "  $name ($count files)"
        fi
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

# Lint the repo: every profile line must resolve to a real file, stack
# profiles need a companion .claude.md, and command names must not collide
# within a profile. Run before committing profile or skill changes.
cmd_validate() {
    local errors=0

    info "Validating profiles..."
    for f in "$SCRIPT_DIR"/profiles/*.txt; do
        [[ -f "$f" ]] || continue
        local pname
        pname="$(basename "$f" .txt)"
        local seen_names=()

        while IFS= read -r line; do
            if [[ "$line" == */* ]]; then
                # Path line (agent def, or an explicit file path)
                if [[ ! -f "$SCRIPT_DIR/$line" ]]; then
                    err "  $pname: missing file: $line"
                    (( errors++ )) || true
                fi
            else
                # Bare skill name → native skill directory skills/<name>/SKILL.md
                if [[ ! -f "$SCRIPT_DIR/skills/$line/SKILL.md" ]]; then
                    err "  $pname: missing skill: $line (expected skills/$line/SKILL.md)"
                    (( errors++ )) || true
                fi
                local seen
                for seen in "${seen_names[@]+"${seen_names[@]}"}"; do
                    if [[ "$seen" == "$line" ]]; then
                        err "  $pname: duplicate skill: $line"
                        (( errors++ )) || true
                    fi
                done
                seen_names+=("$line")
            fi
        done < <(grep -v '^\s*#' "$f" | grep -v '^\s*$')

        # Stack profiles need a companion CLAUDE.md snippet
        _read_profile_metadata "$f"
        if [[ -n "$_STACK_TYPE" && ! -f "$SCRIPT_DIR/profiles/${pname}.claude.md" ]]; then
            err "  $pname: stack profile missing companion snippet profiles/${pname}.claude.md"
            (( errors++ )) || true
        fi
    done

    echo ""
    if [[ $errors -gt 0 ]]; then
        err "Validation failed: $errors error(s)"
        exit 1
    fi
    ok "All profiles valid"
}

# ---- Main ----

COMMAND="${1:-}"
shift || true

DRY_RUN="false"
FORCE="false"
FRESH="false"
CLEAN="false"
NO_CLAUDE_MD="false"
STANDALONE="false"
PROFILE=""
TARGET=""
NEW_PATH=""
HOOKS_SUBCMD=""
EXTRAS=()
STACK_NAMES=()
STACK_DIRS=()

# Grab positional argument for 'new' command (path before any flags)
if [[ "$COMMAND" == "new" && $# -gt 0 && "${1:0:1}" != "-" ]]; then
    NEW_PATH="$1"
    shift
fi

# Grab subcommand for 'hooks' (install|status|uninstall before any flags)
if [[ "$COMMAND" == "hooks" && $# -gt 0 && "${1:0:1}" != "-" ]]; then
    HOOKS_SUBCMD="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile|-p)     PROFILE="$2"; shift 2 ;;
        --stack|-s)
            _stack_spec="$2"
            _stack_name="${_stack_spec%%:*}"
            STACK_NAMES+=("$_stack_name")
            if [[ "$_stack_spec" == *:* ]]; then
                STACK_DIRS+=("${_stack_spec#*:}")
            else
                STACK_DIRS+=("")
            fi
            shift 2
            ;;
        --target|-t)      TARGET="$2"; shift 2 ;;
        --extra|-e)       EXTRAS+=("$2"); shift 2 ;;
        --dry-run|-n)     DRY_RUN="true"; shift ;;
        --force|-f)       FORCE="true"; shift ;;
        --fresh)          FRESH="true"; shift ;;
        --clean)          CLEAN="true"; shift ;;
        --no-claude-md)   NO_CLAUDE_MD="true"; shift ;;
        --standalone)     STANDALONE="true"; shift ;;
        *)                err "Unknown option: $1"; usage ;;
    esac
done

case "$COMMAND" in
    init)           cmd_init ;;
    global)         cmd_global "$DRY_RUN" "$FORCE" "$FRESH" "$NO_CLAUDE_MD" ;;
    new)            cmd_new "$NEW_PATH" "$DRY_RUN" "$FORCE" "$NO_CLAUDE_MD" "$FRESH" "${EXTRAS[@]+"${EXTRAS[@]}"}" ;;
    project)        cmd_project "$PROFILE" "$DRY_RUN" "$FORCE" "$TARGET" "$FRESH" "$NO_CLAUDE_MD" "$CLEAN" "${EXTRAS[@]+"${EXTRAS[@]}"}" ;;
    uninstall)      cmd_uninstall "$DRY_RUN" "$TARGET" ;;
    hooks)          cmd_hooks "$HOOKS_SUBCMD" "$PROFILE" "$TARGET" "$DRY_RUN" "$FORCE" ;;
    status)         cmd_status ;;
    list-profiles)  cmd_list_profiles ;;
    list-skills)    cmd_list_skills ;;
    validate)       cmd_validate ;;
    *)              usage ;;
esac
