# Verification Report: Phase 5 — Install & Profile Integration

## Summary

All five tasks implemented correctly. The install pipeline copies context scaffold templates during project setup, registers `/remember` and `/recall` as on-demand commands, and updates the CLAUDE.md defaults with a Project Context section. Migration handling is graceful (warns without auto-migrating), and the uninstall path includes `context/` in cleanup. Shell script changes follow existing patterns and conventions.

## Results

| Check | Status | Notes |
|-------|--------|-------|
| Tests pass | N/A | Shell script — no automated test suite; verified via code review |
| Matches plan | PASS | All 5 tasks implemented as specified |
| Security | PASS | No secrets, no unsafe operations; file copies use explicit paths |
| Code quality | PASS | New function follows existing install.sh conventions; dry-run supported |
| Scope | PASS | Only the three specified files were modified |
| Integration summary | N/A | No API contracts involved |

## Task-by-Task Verification

### Task 1: Update `install.sh` project command

| Requirement | Status | Location |
|-------------|--------|----------|
| Copy `templates/context/` into `.claude/context/` | PASS | `install.sh:1214-1218` — copies all 4 template files |
| Only copy if context/ doesn't exist | PASS | `install.sh:1194-1196` — guard checks for existing dir, returns early |
| Add to manifest for staleness tracking | PASS | `install.sh:363-373` — enumerates context files in `_write_manifest()` |

Additional observations:
- Function called from both `_install_stacks` (line 1257) and `_install_single_profile` (line 1311) — covers all project install paths
- Dry-run support included (line 1210)
- Creates `patterns/` subdirectory (line 1214)
- Prints `/intel` suggestion after copying (line 1219-1220)

### Task 2: Add commands to `profiles/global.txt`

| Requirement | Status | Location |
|-------------|--------|----------|
| `cmd:remember=skills/memory/remember.md` | PASS | `global.txt:30` |
| `cmd:recall=skills/memory/recall.md` | PASS | `global.txt:31` |

Placed under new "Memory & context (on-demand)" section header, consistent with existing profile organization.

### Task 3: Update `templates/claude-md-defaults.md`

| Requirement | Status | Location |
|-------------|--------|----------|
| "Project Context" section referencing ROUTER.md | PASS | `claude-md-defaults.md:62-67` — references `.claude/context/ROUTER.md` |
| Suggest `/intel` after first install | PASS | `claude-md-defaults.md:65` |
| Suggest `/recall` at session start | PASS | `claude-md-defaults.md:64` |

Also includes `/remember` after sessions (line 66) — good addition not strictly required by plan but consistent with the memory lifecycle.

### Task 4: Handle migration in `install.sh`

| Requirement | Status | Location |
|-------------|--------|----------|
| Don't break existing architecture.md installs | PASS | `install.sh:1194` — returns early if context/ exists |
| Suggest `/intel --full` for migration | PASS | `install.sh:1197-1199` — checks architecture.md + no ROUTER.md, warns |
| Never auto-migrate | PASS | Function only copies templates when context/ is entirely absent |

The migration check is inside the "context/ already exists" branch (line 1194), checking specifically for architecture.md without ROUTER.md — a precise detection of the "monolithic but not yet scaffolded" state.

### Task 5: Update uninstall command

| Requirement | Status | Location |
|-------------|--------|----------|
| Add `context/` to uninstall cleanup | PASS | `install.sh:455` (no-manifest dir removal), `install.sh:540` (empty dir cleanup) |
| Respect "preserve user content" rules | PASS | With manifest: individual file removal. Without manifest: same behavior as other Polaris dirs |

Two locations updated:
1. No-manifest fallback directory list (line 455): `context` added alongside skills, agents, workflows, templates
2. Empty directory cleanup (line 540): `context` added to cleanup sweep

## Issues

### FAIL (must fix)
- None

### WARN (should review)
- None

## Verdict
**PASS**

All five tasks correctly implemented. The install pipeline cleanly integrates context scaffold templates, the global profile registers both memory commands, and the CLAUDE.md defaults guide users toward the context workflow. Migration and uninstall paths are handled gracefully. Shell script changes follow existing conventions throughout.
