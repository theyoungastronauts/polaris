# Plan: July 2026 Review Fixes

Source: full six-dimension review delivered 2026-07-03 (session report; top findings mirrored in project memory `polaris-2026-07-review-findings`). Every finding referenced here was verified against source before inclusion.

## Assumptions (flip any of these and the affected phase changes)

1. **Skills migration scope**: migrate to native `skill-name/SKILL.md` layout with frontmatter (Phase 10); plugin/marketplace distribution is a future plan. → affects Phase 10
2. **Stack priority**: Django + Next.js family now; Flutter is its own phase and can be dropped/deferred; Astro gets no currency work. → affects Phases 6–7
3. **Init settings**: keep the blanket `Bash` allow (intentional for autonomous workflow), remove the placebo deny rules, document what init merges. → affects Phase 3
4. **API contract**: designed fresh from the strongest existing pieces (`/api/v1` prefix, UUIDs, DRF-style pagination via a shipped custom paginator) rather than derived from an existing project repo. → affects Phase 6

## Out of scope (deliberately deferred, per June 2026 decisions — do not re-litigate)

- Astro 6 version bump
- `init` settings confirmation prompt
- Manifest source-tracking for `commands/` staleness

## Sequencing logic

Content fixes land before the layout migration (Phase 10) so file moves don't conflict with edits. Phases 1–3 are independent of each other and could run in parallel worktrees; Phases 5→6→7 are ordered (contract builds on currency fixes; Flutter consumes the contract). Each phase is its own branch + PR (`fix/phase-N-<slug>`), reviewable in one sitting.

---

## Phase 1: Orchestration protocol contradictions

### Objective
`/autopilot`, `/orchestrator`, and `/scaffold` reference only tools that exist, and no two documents disagree about commits, report locations, or plan mode.

### Tasks
1. [ ] Remove `TeamCreate` / `team_name` / "Delete the team" from `skills/execution/autopilot.md` (:24, :26, :81-82), `skills/execution/orchestrator.md` (:70, :148-149), `skills/planning/scaffold.md` (:125-126). Replace with: spawn named agents via the Agent tool `name:` param; address them via SendMessage; no team lifecycle steps. Refresh the "older Claude Code versions" parenthetical.
2. [ ] Commit ownership — single rule: **the session that owns the loop commits; a spawned reviewer never commits.** Make `agents/reviewer.md` step 8 mode-aware (top-level manual session: commit on PASS; spawned subagent: report only, lead commits). Confirm `verify-phase.md` §7 and `workflows/full-feature.md:46` phrase it consistently.
3. [ ] Report location — standardize on project-root `docs/verification/` ("one level above the sub-project"). Add the clause to the reviewer spawn text in `autopilot.md:32` and `orchestrator.md:80` to match `reviewer.md:38` / `verify-phase.md:51`.
4. [ ] Plan mode — make `agents/executor.md` mode-aware: interactive → plan mode + user approval; spawned against a pre-approved plan.md → skip plan mode (the plan is the approval). Mirror in `skills/execution/execute-phase.md`.
5. [ ] Add `agents/executor.md` to `profiles/global.txt` (the global `/autopilot`/`/orchestrator` reference it).

### Output
Five markdown files + one profile edited; no stale tool APIs anywhere in the repo.

### Branch
`fix/phase-1-orchestration-protocol`

### Verification Checklist
- [ ] `grep -rn "TeamCreate\|team_name\|Delete the team" skills/ agents/` returns nothing
- [ ] reviewer.md, verify-phase.md, autopilot.md, orchestrator.md, full-feature.md agree on committer and report path (manual read-through of the four handoff points)
- [ ] `./install.sh validate` passes

---

## Phase 2: Autonomous-loop hardening

### Objective
The autopilot/orchestrator loops handle blocked executors, commit failures, and resume-after-crash instead of falling through to confusing states.

### Tasks
1. [ ] Add a blocked-executor branch to both loops: if the executor reports blocked/stale-plan (not "done with notes"), pause and escalate to the user — do not proceed to lint/test.
2. [ ] Orchestrator direct mode: add an explicit commit step (matches "commit frequently"); remove or make truthful the "Commits made" line in the completion template.
3. [ ] Resume preconditions in both: before executing phase N, run `git status`; if dirty, stop and ask (or instruct stash/reset). State plainly that durable state = per-phase commits; in-session tasks don't survive session death. Fix orchestrator.md:164-169 "marked completed" language.
4. [ ] Add a commit-failed branch: don't mark the phase complete, surface the git error, stop.
5. [ ] Clarify: executor owns inline integration-summary generation in autonomous flows (integrator agent = manual/ad-hoc); parallel groups commit one-per-phase per sub-project, never one spanning commit.
6. [ ] Add maintainer cross-pointer comments in autopilot.md and orchestrator.md ("this loop is duplicated in X — change both").

### Output
autopilot.md, orchestrator.md, executor.md (small), integrator.md (note) updated.

### Branch
`fix/phase-2-loop-hardening`

### Verification Checklist
- [ ] Trace the failure matrix on paper: blocked executor / failed commit / dead session mid-phase each has exactly one defined path in both skills
- [ ] `./install.sh validate` passes

---

## Phase 3: Installer + hooks correctness

### Objective
install.sh fails loudly on bad input, cleans up after profile drift, never deletes user content, and the Stop hook output is actually visible.

### Tasks
1. [ ] `read_profile` (install.sh:423-427): diagnostics to stderr, `return 1` instead of `exit`; add upfront validation of every `--stack`/`--profile` against `profiles/<name>.txt` with a clear "Unknown stack 'x' (available: …)" error before any install work. (Reproduced bug: bad stack name currently exits 0 with help text installed as files.)
2. [ ] Manifest drift: in `_write_manifest`, read the previous manifest first and remove files in old−new (honoring `_is_pristine_context_file`), so dropped/renamed profile entries don't survive reinstall and uninstall.
3. [ ] No-manifest uninstall (install.sh:527-535): stop `rm -rf`ing `commands/`; warn and skip (or move to `.bak`).
4. [ ] Missing-file guard in `_copy_file` (install.sh:285): existence check with `err "profile: path"` instead of raw `cp` abort mid-install.
5. [ ] `echo "$preserved"` → `printf '%s\n'` (install.sh:579, :1092 and the same pattern elsewhere).
6. [ ] `context-pull.sh:83`: strip trailing slash from `BACKEND_PATH` after arg-parse; quote the pattern.
7. [ ] `init` settings (per Assumption 3): remove the two placebo deny rules; keep the Bash allow; print a summary of exactly what was merged; delete dead `merge_arrays` jq (install.sh:151). Document the "re-running init re-asserts plugins/env" behavior in README.
8. [ ] Stop hook visibility: `polaris-stop-summary.sh` emits JSON `hookSpecificOutput.additionalContext` (plain stdout from Stop hooks is not shown). Verify SessionStart stdout behavior is still correct as-is.
9. [ ] Nits if trivial while in there: `shift 7 2>/dev/null || shift 6` dead code; sed delimiter hardening in `_install_alias`.

### Output
install.sh, context-pull.sh, hooks/scripts/polaris-stop-summary.sh, README.md (init section).

### Branch
`fix/phase-3-installer`

### Verification Checklist
- [ ] Scripted scenario run in a scratch dir: bad stack name → non-zero exit + clear error (dry-run and real); drift scenario (install profile A, remove a line, reinstall) → dropped file removed; uninstall with no manifest → user command survives
- [ ] `./install.sh validate` passes; `polaris hooks install --dry-run` output sane
- [ ] Stop hook tested with a synthetic JSON payload piped to the script

---

## Phase 4: Planning schema + memory loop

### Objective
One phase schema, one sizing rule, and a memory write/read loop that actually round-trips.

### Tasks
1. [ ] `plan-and-scope.md`: reduce the phase example (:53-68) to a structural stub (grouping/ordering only) deferring all phase internals to phase-breakdown.md; fix the sizing conflict (:88 "~3 days" → point at phase-breakdown's 1-3h rule); align heading levels with phase-breakdown (`##` phases).
2. [ ] `reflect.md`: rewrite "Memory Organization" (:107-124) to the real convention — one fact per file with `name`/`description`/`metadata` frontmatter, MEMORY.md as a one-line-pointer index. Fix the self-containment violation (:61, :97): instruct reading the installed `remember` skill file before writing context entries, or inline the minimal classify→format→write steps.
3. [ ] `recall.md`: either also load `memory/MEMORY.md` at session start, or retitle to "project context scaffold loader" so it stops claiming to be the whole session-start story.
4. [ ] `remember.md`: replace the duplicated schema blocks (:41-47, :56-72) with "follow the format in the target file's header" (templates stay authoritative).

### Output
Four skill files edited; templates untouched (they're the source of truth now).

### Branch
`fix/phase-4-planning-memory`

### Verification Checklist
- [ ] A plan written following only plan-and-scope + phase-breakdown has exactly one possible phase structure
- [ ] Dry-run the loop on paper: /reflect output → files that /recall (or the harness) actually loads next session

---

## Phase 5: Fullstack security + Django/Next.js currency

### Objective
The canonical fullstack example passes its own verify checklist; no floating or nonexistent pins.

### Tasks
1. [ ] `nextjs-fullstack-bootstrap.md`: add `auth()` + 401 to the GET/POST route handlers (:579-597); add `auth()` to the `createPost`/`deletePost` server actions (:545-560); scope `listPosts` by `session.user.id`. The demo becomes the secure pattern.
2. [ ] Pin `next-auth` to current stable (verify live; expect `^5.x`) at :886/:907; align `@auth/drizzle-adapter`.
3. [ ] Verify current majors via WebSearch and bump: drizzle-orm/drizzle-kit, zod (if zod 4: migrate `.flatten().fieldErrors` usage at :590; if staying on 3: pin and note why), bcryptjs, `@types/node` → `^22` to match .nvmrc/Dockerfile across all Next bootstraps.
4. [ ] `django-bootstrap.md:2259`: `ANTHROPIC_MODEL` default → current verified model ID (`claude-sonnet-5` at time of review — re-verify).
5. [ ] `verify-django.md`: add "SECRET_KEY is not the shipped default in production" check (parallel to fullstack's AUTH_SECRET check).
6. [ ] Security notes: document the localStorage refresh-token XSS tradeoff in nextjs-patterns/bootstrap + offer httpOnly-cookie option; note the `ssl.CERT_NONE` Redis tradeoff (django-bootstrap:688); fix `EmailService.send` returning True on `fail_silently` swallow (:1174); reconcile `AWS_QUERYSTRING_AUTH` contradiction (:809 vs :872) with explicit public-vs-signed intent.

### Output
nextjs-fullstack-bootstrap.md, three nextjs bootstraps (pins), django-bootstrap.md, verify-django.md, nextjs-patterns.md.

### Branch
`fix/phase-5-security-currency`

### Verification Checklist
- [ ] Run `verify-nextjs-fullstack.md` checklist against the bootstrap's own example code — passes
- [ ] Every changed pin confirmed against the live registry (npm/pypi), not memory
- [ ] Model ID confirmed against live Anthropic model list

---

## Phase 6: Canonical cross-stack API contract (Django + Next.js)

### Objective
One documented backend contract; Django ships it; Next.js consumes exactly it.

### Tasks
1. [ ] Add a "Canonical API Contract" section to `django-patterns.md` (source of truth): `/api/v1` prefix; UUID identifiers everywhere; auth endpoints `POST /api/v1/auth/login/`, `POST /api/v1/auth/refresh/`, `GET /api/v1/auth/me/`, register payload `{user, tokens:{access, refresh}}`; pagination response `{page, count, num_pages, results}` with `page`/`page_size` params.
2. [ ] `django-bootstrap.md`: ship a custom DRF paginator emitting that shape and wire `DEFAULT_PAGINATION_CLASS` into the REST_FRAMEWORK block (:701-758); ship the auth URLs the contract names (access/urls.py is currently empty).
3. [ ] `nextjs-bootstrap.md` (and shadcn/mui variants' shared code): confirm endpoints/payloads match the contract exactly; fix divergences.
4. [ ] Cross-reference the contract from `templates/integration-summary.md` so integration summaries inherit it.

### Output
django-patterns.md, django-bootstrap.md, nextjs bootstraps, integration-summary template.

### Branch
`fix/phase-6-api-contract`

### Verification Checklist
- [ ] Grep every endpoint string in nextjs bootstraps — each appears verbatim in the contract section
- [ ] `verify-django.md:32` pagination check is now satisfiable by the shipped bootstrap

---

## Phase 7: Flutter currency + contract alignment (droppable per Assumption 2)

### Objective
Flutter skills target current majors and the Phase 6 contract.

### Tasks
1. [ ] Verify current stable majors live, then migrate `flutter-bootstrap.md` pubspec + `flutter-patterns.md` codegen: Riverpod 3.x (generic `Ref` already used — align the pins), Freezed 3.x (`abstract`/`sealed` class form).
2. [ ] `int? id` → `String uuid` identifiers; resource URLs `/{resource}/$uuid/`; User model keyed on uuid.
3. [ ] Add `infinite_scroll_pagination` to the pubspec and migrate patterns (:808-858) to the current major's API (v5 controller model — verify live).
4. [ ] Align auth endpoints + base URL (`/api/v1` prefix, contract endpoints) with Phase 6; align the pagination parser to `{page, count, num_pages, results}`.
5. [ ] De-duplicate: `flutter-patterns.md` references the bootstrap's canonical DioClient/Failure/Session/PaginatedResponse instead of re-embedding (~200 lines saved in the always-loaded file).

### Output
flutter-bootstrap.md, flutter-patterns.md, verify-flutter.md (pagination package check stays, now satisfiable).

### Branch
`fix/phase-7-flutter`

### Verification Checklist
- [ ] Every package major confirmed against pub.dev
- [ ] Endpoint/ID/pagination greps match the Phase 6 contract

---

## Phase 8: Verification coverage gaps

### Objective
Every stack with patterns has a verify checklist that checks what the patterns emphasize.

### Tasks
1. [ ] New `skills/verification/verify-nextjs-mui.md` (sx discipline, AppRouterCacheProvider/Emotion SSR, InitColorSchemeScript, Grid `size`) and `verify-nextjs-shadcn.md` (components.json, `cn()`, next-themes, ui/ import paths). Keep them small — checklist files, not essays.
2. [ ] Tailwind-v4 items (no tailwind.config, `@theme`, OKLCH, CVA, no forwardRef) — add to the frontend verify files that pair with `/tailwind` rather than a standalone file.
3. [ ] `verify-nextjs.md`: add trailing-slash, dates-as-strings-via-dayjs, single-`lib/api.ts` namespacing items (its own patterns file emphasizes all three); add a pointer to the `/react` 57-rule set for the Performance section.
4. [ ] Wire new verify files into `profiles/nextjs-mui.txt` / `nextjs-shadcn.txt`; update README On-Demand table.

### Output
Two new verify skills, two edited, two profiles, README.

### Branch
`fix/phase-8-verify-coverage`

### Verification Checklist
- [ ] For each `*-patterns.md` rule marked "always/never", a matching verify item exists (spot-check ten)
- [ ] `./install.sh validate` passes

---

## Phase 9: Token economy + repo hygiene

### Objective
Nothing always-loaded that shouldn't be; docs match reality; nothing dead ships.

### Tasks
1. [ ] `profiles/global.txt`: `skills/git/worktrees.md` → `cmd:worktrees=`, `skills/meta/writing-skills.md` → `cmd:writing-skills=` (update the references in phase-breakdown.md:34, full-feature.md:60, repo CLAUDE.md).
2. [ ] Add `workflows/full-feature.md` to global.txt (documented everywhere, installed nowhere).
3. [ ] Delete `templates/architecture.md` (dead); annotate `templates/context/ROUTER.md` that `architecture.md` is generated by `/intel` (not shipped); same note in README's scaffold table (:194).
4. [ ] README fixes: templates/ tree lists claude-md-defaults.md; profiles table `nextjs` label matches the snippet (Tailwind, not DaisyUI — or add DaisyUI to the snippet, whichever is true); note that `skills/misc/` is intentionally user-specific (sanctions the vfx.md exception).
5. [ ] llms.txt: complete the installer command list; sync file tree.
6. [ ] Document `docs/plans/` + `docs/verification/` as Polaris's own working artifacts in repo CLAUDE.md (keep the files; they're history).
7. [ ] Remove `.vscode/settings.json` from tracking (or strip to non-cosmetic keys); add `.vscode/` to .gitignore.
8. [ ] Multi-frontend guard: in `_merge_profiles` (or a validate cross-check), error when two selected stacks map different files to the same `cmd:` name instead of silently keeping the first.
9. [ ] `templates/claude-md-defaults.md`: split stack-agnostic defaults from the Django/Next block; mark the stack section as replace-me example.

### Output
global.txt, README.md, llms.txt, CLAUDE.md, ROUTER.md template, install.sh (guard), .gitignore; one file deleted.

### Branch
`fix/phase-9-hygiene`

### Verification Checklist
- [ ] `./install.sh validate` passes; fresh `global` install in scratch HOME produces a CLAUDE.md block listing the new commands
- [ ] Consistency re-greps: no doc references a file that doesn't ship; no profile-less documented artifact remains

---

## Phase 10: Native skills migration (Assumption 1)

### Objective
Polaris skills auto-trigger via native SKILL.md discovery; the generated CLAUDE.md block shrinks to project-structure context.

### Tasks
1. [ ] Design pass (30 min, in-plan doc update): mapping table — which files become auto-triggering skills (patterns, conventions, discipline), which stay explicit slash commands (execute, verify, autopilot, orchestrator, scaffold, prd…), which get `paths` scoping (stack skills → their stack directory glob).
2. [ ] Restructure `skills/` to `skill-name/SKILL.md` directories with frontmatter (`name`, `description` written per writing-skills' own trigger-description guidance; `paths` where scoped; `disable-model-invocation` for command-only ones).
3. [ ] install.sh: copy skill directories; installed location `~/.claude/skills/` and `.claude/skills/` per native spec; `cmd:` entries unchanged; shrink `_emit_polaris_block` to Project Structure + agents (+ commands list) — skills no longer need the pointer list.
4. [ ] Agents: enrich frontmatter — `tools` where restriction makes sense, `memory` for reviewer/planner (cross-session learning), `model` left default.
5. [ ] Update `writing-skills.md` File Organization/Naming to match the new (now actually true) layout; drop the gerund mandate in favor of the repo's real naming.
6. [ ] Migration note for existing installs: Phase 3's manifest diffing removes the old flat files on next `--force` install; document "run `polaris project --force`" as the upgrade path in README.

### Output
Whole `skills/` tree restructured; install.sh, writing-skills, README, all profiles updated (paths change).

### Branch
`feat/phase-10-native-skills`

### Verification Checklist
- [ ] Fresh install into a scratch project; open a Claude session; confirm a stack skill auto-triggers on a matching file edit and a `disable-model-invocation` skill doesn't
- [ ] `./install.sh validate` passes with updated paths; `polaris status` clean
- [ ] Upgrade path tested: old-layout install → `--force` → no orphaned flat files
