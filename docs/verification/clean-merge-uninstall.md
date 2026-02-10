# Verification Report: Clean, Merge, Uninstall

## Summary

All planned features are implemented in `install.sh` and working correctly. Manifest tracking, `--clean` flag, `polaris uninstall`, and `--fresh` project support all pass functional testing. The implementation follows existing patterns and handles edge cases (no manifest fallback, user content preservation, empty directory cleanup).

## Results

| Check | Status | Notes |
|-------|--------|-------|
| Tests pass | PASS | All 7 functional tests pass (dry-run, install, clean+reinstall, uninstall, user content preservation, idempotency, no-manifest fallback, legacy profile mode) |
| Matches plan | PASS | All 7 implementation items complete. One minor deviation: manifest `stacks` field uses `{"django": "server"}` object instead of `["django"]` array — an improvement that preserves directory mappings |
| Security | PASS | Controlled paths only, `rm` on individual tracked files, `rm -rf` limited to known Polaris subdirectories, backups before destructive CLAUDE.md changes |
| Code quality | PASS | Clean functions, consistent with existing patterns, dry-run support on all new paths, `set -euo pipefail` maintained |
| Scope | PASS | All changes in `install.sh` as planned. Profile changes (`global.txt`, `nextjs.txt`) and new skill files are independent additions, not part of this plan |
| Integration summary | N/A | No API endpoints involved |

## Functional Tests Performed

1. `polaris project --dry-run --stack django --stack nextjs` — correct output, no side effects
2. `polaris project --stack django --stack nextjs` on scratch project — manifest created with correct JSON, CLAUDE.md generated
3. `polaris project --clean --stack django --stack nextjs` — 13 files removed via manifest, reinstalled fresh
4. `polaris uninstall` — all Polaris files removed, `.claude/` left empty
5. Uninstall with user content in CLAUDE.md — backup created, user content preserved, Polaris block stripped
6. Idempotency: two consecutive installs — files skipped on second run, only 1 `polaris:start` marker
7. Uninstall without manifest — falls back to removing standard directories (`skills/`, `agents/`, etc.)
8. Legacy `--profile` mode — manifest written with empty stacks object, correct file list

## Plan Item Checklist

- [x] `_write_manifest()` + call sites in `_install_stacks` and `_install_single_profile`
- [x] `_read_manifest_files()` helper (with jq + grep/sed fallback)
- [x] `_clean_project()` function (manifest-aware + fallback)
- [x] `--clean` flag on `cmd_project()` + arg parsing
- [x] `--fresh` enabled for projects (no more warning, wired up)
- [x] `cmd_uninstall()` + arg parsing + usage
- [x] `usage()` updated with new options and examples

## Issues

### FAIL (must fix)

None.

### WARN (should review)

None.

## Verdict

PASS
