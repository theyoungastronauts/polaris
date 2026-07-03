# Verification Report: Phase 3 — Installer + hooks correctness

## Summary
All nine Phase 3 tasks are now implemented correctly. The critical context-scaffold-deletion bug found in the first pass (routine `--force` reinstall deleting the pristine scaffold) has been fixed and re-verified empirically: the scaffold now survives `--force`, populated files stay preserved, and genuine drift removal still works (no overcorrection). `./install.sh validate` and `bash -n install.sh` are clean. One minor cleanliness item remains — the `CONTEXT_TEMPLATES_COPIED` variable is now dead (assigned, never read). **Verdict: PASS WITH WARNINGS.**

All tests were run in an isolated scratch `HOME` against the real repo; no changes to the user's environment.

## Re-verification (after context-scaffold fix)

The fix removed the `CONTEXT_TEMPLATES_COPIED` gate in `_write_manifest`: the four scaffold files (`context/ROUTER.md`, `decisions.md`, `conventions.md`, `patterns/README.md`) are now added to `new_paths` whenever they exist on disk under `$claude_dir`, so a reinstall keeps tracking them and the drift loop never misclassifies them as "no longer tracked." The drift-removal loop itself is unchanged.

| Re-test | Result |
|---------|--------|
| Fresh install → `--force` reinstall (same stack) → all 4 scaffold files survive | PASS — only "context/ already exists — skipping template copy" prints; no "removed" lines. Scaffold count 4/4. |
| Edit `decisions.md` → `--force` → edit preserved AND 3 pristine siblings preserved | PASS — "USER EDIT MARKER" intact, 4/4 scaffold files present. |
| Inject bogus tracked non-context file → `--force` → bogus removed (no overcorrection) | PASS — "removed (no longer tracked): skills/bogus-dropped.md"; scaffold still 4/4. |
| `bash -n install.sh` | PASS (clean). |
| `./install.sh validate` | PASS (exit 0). |

The fix is correctly scoped: context files are now protected from drift removal (a truly-orphaned context template would persist rather than be swept — the safe tradeoff), while non-context profile drift is still removed as before.

## Assumptions / Out-of-scope re-check
- **Assumption #3** (keep the blanket `Bash` allow, remove the placebo deny rules, document what init merges) — honored. `init` prints a summary of what it asserted (allow list incl. `Bash`, `enabledPlugins`, `env`); the `deny` array is gone from `REQUIRED_SETTINGS` and the merged output; the dead `merge_arrays` jq is removed; README updated.
- **Out-of-scope items** (Astro 6 bump, init settings confirmation prompt, manifest source-tracking for `commands/` staleness) — untouched. Still hold.

## Results

| Check | Status | Notes |
|-------|--------|-------|
| Bad-stack validation | PASS | exit 1 + "Unknown stack 'x' (available: …)", no files created (dry-run + real). |
| Drift removal (dropped file) | PASS | Bogus tracked file removed on `--force`; real tracked file survives. |
| Context scaffold on `--force` | PASS | Fixed — all 4 files survive; populated files preserved. |
| No-manifest uninstall | PASS | User-authored `commands/` file survives; warns instead of `rm -rf`. |
| Stop hook JSON | PASS | Emits valid `hookSpecificOutput.additionalContext`; dedups; resets store; no-store → silent exit 0. |
| init summary / settings | PASS | Summary printed; Bash allow kept; deny removed; merge_arrays gone. |
| `./install.sh validate` | PASS | exit 0. |
| `hooks install --dry-run` | PASS | Sane preview output. |
| Code quality | WARN | `CONTEXT_TEMPLATES_COPIED` now dead (see WARN below). |
| Scope | PASS | Only the 4 Output files touched. |

## Task-by-task

1. **`read_profile` hardening + upfront validation** — PASS. Diagnostics to stderr with `return 1`; `_validate_requested_profiles` runs before install work in both `cmd_project` and `cmd_new`. Empirically: bad stack (dry-run + real) exits 1 with a clear available-stacks list, no `.claude/` created.
2. **Manifest drift removal (honoring `_is_pristine_context_file`)** — PASS (after fix). Dropped tracked files are removed; the pristine context scaffold is now preserved across `--force`; populated context files are preserved.
3. **No-manifest uninstall** — PASS. `rm -rf commands/` replaced with warn-and-keep; user-authored command survives.
4. **Missing-file guard in `_copy_file`** — PASS. `[[ ! -f "$SKILLS_REPO/$src" ]] && err … && return 1` before copy.
5. **`echo "$preserved"` → `printf '%s\n'`** — PASS. All three preserved-content sites.
6. **`context-pull.sh` trailing slash + quoting** — PASS. `${BACKEND_PATH%/}` post-arg-parse; both prefix strips quote the variable.
7. **init settings** — PASS. Deny removed, Bash allow kept, `merge_arrays` deleted, summary printed, README updated.
8. **Stop hook JSON + SessionStart check** — PASS. Valid `hookSpecificOutput` JSON, dedup, store reset, silent no-store exit; SessionStart correctly left as plain stdout.
9. **Nits** — PASS. `shift 7`; `_install_alias` sed-special-char escaping.

## Issues

### FAIL (must fix)
- None. (The first-pass context-scaffold-deletion FAIL is resolved — see Re-verification above.)

### WARN (should review)
- `install.sh` — `CONTEXT_TEMPLATES_COPIED` is now a dead variable: initialized at :2074 and assigned at :1332 and :1341 (in `_install_context_templates`), but read nowhere after the fix removed its only consumer (the sole remaining mention at :360 is an explanatory comment). It is inert — no correctness impact — but the repo's own standards discourage leaving dead code. **Recommendation:** drop the `="false"` init (:2074) and the two `="true"` assignments (:1332, :1341); the fix touches the same `_install_context_templates`/`_write_manifest` area, so folding this cleanup into the Phase 3 commit is natural, or it can be a trivial follow-up. Not a blocker — the lead's call on commit-now vs. tidy-first.

### Suggestions (optional)
- `hooks/scripts/polaris-stop-summary.sh` is tracked non-executable (`-rw-r--r--`). Not introduced by this phase and irrelevant if Claude Code invokes hooks via a shell; worth confirming the hook runner doesn't rely on the exec bit. Out of scope for Phase 3.

## Verdict
**PASS WITH WARNINGS** — all nine tasks correct and empirically verified; the critical bug is fixed. The single WARN is a now-dead `CONTEXT_TEMPLATES_COPIED` variable (inert cleanliness item) the lead may fold into the commit or defer.
