# Independent Review: July 2026 Fix Stack (phases 1–10)

**Scope:** all 10 stacked branches `fix/phase-1-orchestration-protocol` → `feat/phase-10-native-skills` (87 files, +1936/−808) against `docs/plans/2026-07-03-review-fixes-plan.md`.
**Method:** six parallel diff reviewers (one per phase group) + first-hand end-to-end installer scenarios in a sandboxed HOME + live doc verification of the Stop-hook contract. Every finding below was independently verified against the tree or reproduced; reviewer claims that didn't survive verification were dropped.

## Verdict: PASS WITH WARNINGS

The plan was substantially and correctly implemented. Merge-worthy, with one HIGH content bug and a mechanical path-sweep to land before or immediately after merge.

### Verified working (highlights)

- All Phase 1/2 protocol contradictions resolved and consistent across the four handoff points; `TeamCreate`/`team_name` fully gone; `./install.sh validate` passes.
- Installer end-to-end: bad `--stack` fails loudly pre-copy (exit 1, clear message); manifest drift removal works (`--force` reinstall removes dropped-stack files, protects populated context); no-manifest uninstall preserves user `commands/`; init prints its settings merge and no longer writes placebo deny rules.
- Canonical API contract genuinely shipped: correct DRF paginator wired in both settings blocks, access app implemented and mounted at `/api/v1/auth/`, `USER_ID_FIELD="uuid"`, rotation semantics consistent with frontend token reuse.
- Phase 5 security fixes complete and coherent (auth() + scoping through routes/actions/services, session plumbing, index added); pins verified against live registries (next-auth 5.0.0-beta.31, drizzle ^0.45, zod ^4.4 with flatten→flattenError migrated, bcryptjs ^3, @types/node ^22, `claude-sonnet-5`).
- Flutter fully migrated: Riverpod 3 / Freezed 3 (live-verified pins), uuid identifiers, infinite_scroll_pagination v5 API, contract-aligned endpoints/pagination, dedup done.
- Phase 10 mechanism sound: all 46 SKILL.md frontmatter parse, only real fields used, command-vs-auto-trigger split coherent, extension-based `paths` globs (`**/*.py`, `**/*.dart`) elegantly sidestep the configurable-stack-dir problem, content integrity preserved via git mv, both commit-claimed follow-ups genuinely resolved, README `--force` upgrade note accurate for manifest-bearing installs.
- Stop hook: doc-verified that `hookSpecificOutput.additionalContext` IS honored on Stop (shown end-of-turn); the stack's implementation is correct.

## Must fix (before or immediately after merge)

1. **HIGH — signup 400s on all three decoupled Next.js bootstraps.** `username` appears 0 times in nextjs/nextjs-mui/nextjs-shadcn bootstraps, but the contract (`django-patterns/SKILL.md:63,68`) and shipped `RegisterSerializer` (`django-bootstrap/SKILL.md:1377`) require it. Add `username` to `RegisterRequest` + `User` + register forms in all three (mirror the Flutter fix). Root cause: Phase 6 verification grepped endpoint strings, not payload shapes.
2. **MEDIUM — post-migration path sweep (one root cause, several sites).** Phase 10's cross-reference sweep was incomplete:
   - All 7 `profiles/*.claude.md:5` ship dead `skills/execution/<x>-patterns.md` into every consumer CLAUDE.md (drop the line — patterns auto-trigger now — or repoint).
   - `skills/scaffold/SKILL.md:135` tells spawned agents to read bootstraps at `.claude/commands/{bootstrap_command}.md` → now `.claude/skills/{name}/SKILL.md`. Runtime breakage in the scaffold flow.
   - `skills/reflect/SKILL.md:67,102` points at `.claude/commands/remember.md` / `skills/memory/remember.md` — both gone (Phase 4's own fix, broken by Phase 10).
   - Maintainer cross-pointers: `skills/autopilot/SKILL.md:47` ↔ `skills/orchestrator/SKILL.md:122` name pre-migration paths.
3. **MEDIUM — pagination shape drift.** `nextjs-fullstack-patterns/SKILL.md:127` and `verify-nextjs-fullstack/SKILL.md:35` still specify `{data, meta}`; the bootstrap now ships canonical `{page, count, num_pages, results}`. Update both.
4. **MEDIUM — Flutter half-migrated examples.** Filtering example (`flutter-patterns/SKILL.md:717-731`): `/books/` missing `/api/v1`, `limit` param the shipped paginator ignores, `int limit` contradicts the interface. Testing example (`:749-754`): `Book(id: 1, ...)` + `retrieve(1)` won't compile against the uuid model.
5. **Branch decision — delete `fix/hooks-stop-visible`.** Orphan branch off main duplicating the Phase 3 Stop-hook fix with `systemMessage`, which is NOT documented for Stop; the stack's `additionalContext` version is the documented mechanism. Deleting the branch resolves the guaranteed merge conflict.

## Docs sweep (medium, non-blocking)

- `README.md:90-95` attribution table (6 stale paths), `:169`, `:253-254` example output; structure tree still shows `workflows/`.
- Repo `CLAUDE.md:45-46,55,57`: still documents removed `cmd:name=path` syntax and `.claude/commands/` install; structure tree lists deleted `skills/` subdirs. A contributor following it would author skills wrong.
- `llms.txt:111,161,175,187,206`; `USAGE.md:44,56,139,500`.
- `agents/executor.md:27`: "the verifier will commit" → "the review session (or orchestrating lead) commits."

## Low / latent

- Manifest records only `skills/<name>/SKILL.md` while `copy_skill_dir` copies every file — first skill that bundles a supporting file gets it orphaned on uninstall/drift. Fix when (or before) any skill grows a second file.
- Drift removal leaves empty skill directories (7 observed in testing); add an `rmdir` sweep.
- `--stack global` is accepted as a stack and suggested in the unknown-stack error text.
- Pre-manifest installs: `--force` upgrade path silently leaves old flat files (no manifest to diff) — needs one README sentence recommending `uninstall` first.
- `skills/reflect/SKILL.md:52` still asks global-vs-project scope; only the project store is documented.
- `verify-nextjs-fullstack/SKILL.md:43` requires Zod in server actions; the canonical `createPost` action validates manually.
- Cosmetic: `_emit_polaris_block` hardcodes `.claude/skills/` (wrong for global installs at `~/.claude/skills/`); `[id]` route segment naming carries uuids; install.sh:241/:868 stale comments; residual colloquial "team" wording.

## Process notes

- `docs/plans/2026-07-03-review-fixes-plan.md` is untracked — commit it (CLAUDE.md now designates docs/plans as kept history).
- Some per-phase verification reports in docs/verification/ contain WARNs that later phases resolved (phase-4 scope leftover, phase-5 patterns flatten, phase-9 worktrees refs). Accurate as point-in-time records; noted so nobody re-fixes them.
- Suggested merge: single PR from `feat/phase-10-native-skills` (contains the whole stack), then delete the nine intermediate branches and `fix/hooks-stop-visible`.
