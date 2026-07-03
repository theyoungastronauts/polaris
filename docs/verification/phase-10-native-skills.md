# Verification Report: Phase 10 — Native skills migration

## Summary
The migration is correct and complete in its core: all 46 skills are now `skills/<name>/SKILL.md` directories with valid frontmatter whose `name` matches the directory; the 12 SKILL.md bodies I spot-checked across all three categories are **byte-identical** to their pre-migration content (only frontmatter added); the install.sh rewrite (`copy_skill_dir`, routing, shrunk CLAUDE.md block, rewritten `cmd_validate`) is sound; the Phase 9 cmd-conflict guard is correctly retired because per-skill unique naming makes that conflict class structurally impossible; the agent `tools:` allowlists correctly include WebSearch/WebFetch (bug 2a) and exclude Edit on reviewer/drift-detector; and the README upgrade note accurately matches the manifest-diffing behavior. `./install.sh validate` passes and all 9 profiles resolve. **Found one residual instance of the lead's bug-2b class** (a stale `/nextjs-bootstrap` reference in a shared patterns file), plus two latent install.sh robustness gaps and one memory-scope design question. **Verdict: PASS WITH WARNINGS.**

## Results

| Check | Status | Notes |
|-------|--------|-------|
| Task 1 — design/categorization | PASS | 32 command-only / 10 auto / 4 paths-scoped; coherent. |
| Task 2 — restructure | PASS | 46 SKILL.md; names match dirs; bodies intact (12 spot-checked). |
| Task 3 — install.sh rewrite | PASS (2 latent WARN) | Logic correct; two robustness gaps below. |
| Task 4 — agent frontmatter | PASS (1 discussion) | Bug 2a fixed; Edit excluded correctly; `memory:` scope Q below. |
| Task 5 — writing-skills.md | PASS | Layout/Naming rewritten to real flat SKILL.md model; gerund mandate dropped. |
| Task 6 — migration docs | PASS | README upgrade note matches the manifest-diff code. |
| Retired conflict guard (item 4) | PASS | Conflict class now structurally impossible. |
| Profiles resolve (item 5) | PASS | Every bare name → `skills/<name>/SKILL.md`; agent paths resolve; validate clean. |
| Stale self-refs (bug-2b class) | WARN | `nextjs-patterns/SKILL.md:51` residual `/nextjs-bootstrap`. |

## Verified in detail

### Task 2 — restructure + body integrity (item 2)
46 SKILL.md files, flat `skills/<name>/` layout; the only non-SKILL.md flat file is the documented `misc/vfx.md` extras exception. Every frontmatter opens with `---`, every `name:` equals its directory (required for native discovery), and every description is present and quoted where needed. Category flags are internally consistent: 32 command-only carry `disable-model-invocation: true`; 4 are paths-scoped (`django-patterns`→`["**/*.py"]`, `flutter-patterns`→`["**/*.dart"]`, `astro-patterns`→`["**/*.astro"]`, `writing-skills`→`["**/SKILL.md"]` with no `disable-model-invocation`, so it both auto-triggers and stays manually invocable — matching the lead's design); the remaining 10 are plain auto-trigger.

**Body integrity:** I diffed 12 SKILL.md bodies (frontmatter stripped) against their pre-migration files on `fix/phase-9-hygiene` — `verify-django`, `django-bootstrap`, `nextjs-mui-bootstrap`, `react`, `autopilot`, `scaffold` (command); `nextjs-patterns`, `plan-and-scope`, `work-discipline`, `commit-conventions` (auto); `django-patterns`, `flutter-patterns` (paths-scoped). **All 12 are byte-identical** — the migration added frontmatter and moved files, nothing was truncated or corrupted. `writing-skills` differs, as expected, by exactly its Task 5 edits.

### Task 3 — install.sh (item 3, read line-by-line)
- **`copy_skill_dir`** copies **every** file under `skills/<name>/` (`find … -type f`), not just SKILL.md, each via `_copy_file` (checksum/stale detection preserved), and guards a missing dir/SKILL.md with a clear error. Structure is preserved into `.claude/skills/<name>/`.
- **Routing** (`_install_line`, `_profile_lines_to_paths`): bare name → skill dir; path (`agents/…`, `templates/…`) → file preserving path. Correct.
- **`_categorize_lines` / `_emit_polaris_block`**: block shrunk to Project-Structure + Agents + a command-only list; auto-triggering skills are (correctly) omitted since native discovery surfaces them. The `grep -q '^disable-model-invocation: true'` gate correctly selects the command list — **all 32 command-only files match that exact string** (verified: 32 with the field, 32 exact-match, zero variants), so the current CLAUDE.md list is correct. (Brittleness caveat → WARN below.)
- **`cmd_validate`** rewritten: path lines checked for file existence; bare names checked for `skills/<name>/SKILL.md` + duplicate detection. Correct for the new layout.

### Task 4 — agent frontmatter (item 6)
- **Bug 2a fixed:** `reviewer`, `planner`, `drift-detector`, `integrator`, `design-intake` all list `WebSearch, WebFetch` in their `tools:` allowlist; `executor` is intentionally unrestricted (it implements code). Correct — the allowlist is inclusive, not exclusionary.
- **`Edit` exclusion** on `reviewer` and `drift-detector` is correct: both have `Write` (reports) and `Bash` (git/commits) but no `Edit`, enforcing "report, don't modify source."
- **`memory: project`** on reviewer/planner → see the memory-scope discussion under Issues.

### Task 5 — writing-skills.md (item 7)
The File Organization/Naming section now describes the real layout: "Every skill is a `skills/<skill-name>/SKILL.md`" with a frontmatter template (`name`, trigger-focused `description`, optional `disable-model-invocation`/`paths`), and Naming reads "Kebab-case directory names. For a command-only skill the directory name *is* the slash command … For an auto-triggering skill use a clear noun/verb phrase … Match the repo's existing names; **don't force gerunds**." The old gerund mandate (`creating-skills` not `skill-creation`) is gone. Accurate to reality.

### Task 6 — migration docs (item 8)
README:264 documents the upgrade path: `--force` reinstall installs the new `skills/<name>/SKILL.md` dirs and, via manifest diffing, removes the old flat `skills/<cat>/*.md` and `commands/*.md`. This matches the Phase 3 `_write_manifest` drift-removal (old−new paths removed): a pre-native manifest lists flat/`commands/` paths absent from the new `skills/<name>/SKILL.md` set, so they're swept. The lead's live old-layout→`--force` test (zero orphans) confirms it.

### Item 4 — retired conflict guard (structurally impossible)
`_merge_profiles` now dedups by exact line. The retired Phase 9 guard existed because two profiles could bind the same `/cmd` name to different files (`cmd:nextjs-bootstrap` → mui vs shadcn). Under native skills a profile line **is** a skill directory name, which resolves globally to exactly one `skills/<name>/SKILL.md`. Two profiles naming the same skill resolve to the same file (deduped); different skills have different names (filesystem-unique). So the same name can never map to two different files — the conflict class is eliminated, not merely reduced. Confirmed by the per-variant names now in the profiles (`nextjs-mui-bootstrap` vs `nextjs-shadcn-bootstrap`).

## Issues

### FAIL (must fix)
- None.

### WARN (should review)
- **Residual bug-2b-class stale reference — `skills/nextjs-patterns/SKILL.md:51`.** It says "Use `/nextjs-bootstrap` when setting up a new project from scratch," but `nextjs-patterns` is loaded by **four** profiles (`nextjs`, `nextjs-mui`, `nextjs-shadcn`, `nextjs-fullstack`), and after Phase 10's per-variant command split only the plain `nextjs` profile actually installs `/nextjs-bootstrap` — the other three install `/nextjs-mui-bootstrap`, `/nextjs-shadcn-bootstrap`, `/nextjs-fullstack-bootstrap`. So for 3 of 4 consuming projects this points at a command that isn't installed. This is exactly the class the lead fixed in `profiles/nextjs-mui.claude.md` (bug 2b), missed here because it lives in a shared patterns body. Pre-Phase-10 it was correct (all variants shared the `/nextjs-bootstrap` command name — the old conflict); Phase 10's rename made it stale. Not broken for plain `nextjs`, but misleading for the variants. **Fix:** generalize, e.g. "use your stack's Next.js bootstrap command (`/nextjs-bootstrap`, `/nextjs-mui-bootstrap`, `/nextjs-shadcn-bootstrap`, or `/nextjs-fullstack-bootstrap`)." *Lower-confidence related spots:* `skills/scaffold/SKILL.md:30` (stack→command table lists only `--stack nextjs → /nextjs-bootstrap`, no mui/shadcn rows) and `:150` (illustrative "`/django-bootstrap` or `/nextjs-bootstrap`"); worth a quick sweep for hardcoded `/nextjs-bootstrap` while fixing :51.
- **Manifest under-tracks multi-file skills (latent).** `copy_skill_dir` copies *every* file under a skill dir, but `_profile_lines_to_paths` records only `skills/<name>/SKILL.md` in the manifest. Today every skill is SKILL.md-only, so there's **no current impact**, but a future skill with subfiles (`references/`, `scripts/`, which the native spec allows) would have those subfiles copied yet untracked — so drift-removal/uninstall would orphan them. **Fix when multi-file skills appear:** have `_profile_lines_to_paths` enumerate the skill dir's files (mirror `copy_skill_dir`) instead of assuming SKILL.md only.
- **`_categorize_lines` exact-match brittleness (latent).** The command-list gate `grep -q '^disable-model-invocation: true'` requires that exact spacing/casing. All 32 current files match, so the CLAUDE.md list is correct now — but a hand-authored future skill written `disable-model-invocation:true`, `: "true"`, extra spaces, or a trailing comment would be YAML-valid (Claude Code would still treat it command-only) yet silently omitted from the CLAUDE.md slash-command list. **Fix:** tolerate whitespace/quoting (e.g. normalize before matching) or parse the value YAML-aware.

### Discussion (item 6 — memory scope)
- **`memory: project` on reviewer/planner.** `project` scope means the agent's cross-session memory is written into the consumer's `.claude/` and **checked into their version control**. For a tool that installs into other people's repos, `local` (gitignored `.claude/*-local/`) is arguably the safer default — it avoids forcing auto-generated agent-memory files and their churn into a consumer's git history without their say-so. `project` is defensible *if* the intent is deliberately team-shared review/plan learning — but then it should be documented so consumers know Polaris will add committed files. Recommend either switching reviewer/planner to `local` or documenting the `project` choice in the README. (Not a bug; a default-choice worth a conscious decision. `Edit` exclusion, the other half of item 6, is correct.)

## Verdict
**PASS WITH WARNINGS** — the migration is structurally correct: bodies intact, frontmatter valid and correctly categorized, install.sh rewrite sound, conflict guard safely retired, agent tools/Edit correct, validate + upgrade path working. The actionable WARN is the residual `/nextjs-bootstrap` stale reference in `nextjs-patterns/SKILL.md:51` (same class as the lead's bug-2b fix, affecting 3 of 4 consuming profiles); the other two WARNs are latent install.sh robustness gaps with no current impact; and the `memory: project` default is a conscious-decision item for the lead.
