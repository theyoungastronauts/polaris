# Plan: Flutter Stack Profile

## Goal
Bring Houston's proven Flutter patterns into Polaris as a first-class stack profile — replacing the current lightweight skill with comprehensive architecture guidance, an interactive bootstrap skill, and an updated verification checklist. Django-paired only (for now).

## Scope

### In Scope
- Rewrite `flutter-patterns.md` with full architecture conventions and inline code examples (12 sections from brainstorm)
- Create `flutter-bootstrap.md` — interactive scaffold for app shell + auth feature
- Update `verify-flutter.md` to align with new patterns (sealed Failures, service interfaces, @riverpod codegen)
- Update `profiles/flutter.txt` to include the bootstrap skill

### Out of Scope
- Multi-backend support (Supabase, ServePod) — future work
- Porting Mason bricks or blueprint YAML — Claude replaces the generation engine
- CI/CD workflows — noted as open question, deferred
- Changes to the existing Django profile or cross-repo workflow
- Houston CLI or client package

## Repo Strategy
Single repo: this is all within `polaris/` (skills, profiles, verification).

## Phases

---

## Phase 1: Flutter Patterns Skill

### Objective
Replace the lightweight `flutter-patterns.md` with a comprehensive architecture guide that covers all 12 sections identified in the brainstorm, with inline code examples for every layer.

### Input
- Brainstorm: `docs/plans/2026-02-08-flutter-stack-brainstorm.md`
- Houston Flutter source: `/Users/tyler/prj/houston/houston_flutter/lib/`
- Houston review: `/Users/tyler/prj/houston/REVIEW.md`
- Existing skill: `skills/execution/flutter-patterns.md`

### Tasks
1. [ ] Read Houston source (profile feature, auth feature, core/) to extract proven conventions
2. [ ] Write the full `flutter-patterns.md` covering all 12 sections:
   - Project structure & naming conventions
   - Models (Freezed + json_serializable)
   - Services (abstract interface + Django implementation)
   - Providers (@riverpod codegen, AsyncNotifier for forms/lists)
   - Screens (BaseScreen, consuming providers, navigation)
   - Widgets (extraction rules, const constructors, composition)
   - API client (Dio setup, interceptors, token refresh)
   - Auth (JWT session, secure storage, auth state provider, route guards)
   - Error handling (sealed Failure types, provider error surfacing)
   - Forms (validation, submission, loading states, image upload)
   - Lists (infinite scroll, paginated, filtering, ordering)
   - Testing (unit/widget tests, mocking patterns)
3. [ ] Modernize patterns from Houston (drop fpdart, use @riverpod codegen, AsyncNotifier, flattened structure)
4. [ ] Keep file concise — token cost matters. Code examples should be minimal but complete enough to copy.

### Output
- `skills/execution/flutter-patterns.md` — complete rewrite

### Suggested Skills
- `skills/meta/writing-skills.md` (for structure guidance)
- `skills/writing/writing-clearly.md` (for conciseness)

### Branch
`feature/flutter-stack-phase-1`

### Verification Checklist
- [ ] All 12 sections present with code examples
- [ ] Patterns match brainstorm decisions (no fpdart, flattened structure, @riverpod codegen)
- [ ] Self-contained — readable without loading other files
- [ ] Concise — no unnecessary prose, examples are minimal but copy-worthy
- [ ] Consistent with existing Polaris skill format

### Estimated Complexity: L

---

## Phase 2: Flutter Bootstrap Skill

### Objective
Create an interactive bootstrap skill that scaffolds a Flutter app shell + auth feature, consistent with the patterns defined in Phase 1.

### Input
- Completed `flutter-patterns.md` from Phase 1
- Brainstorm bootstrap section (core shell + auth feature specs)
- Houston auth implementation: `/Users/tyler/prj/houston/houston_flutter/lib/features/auth/`
- Houston core: `/Users/tyler/prj/houston/houston_flutter/lib/core/`

### Tasks
1. [ ] Define the interactive config prompts (API URL, app name, bundle ID, platforms, etc.)
2. [ ] Write bootstrap instructions for core shell:
   - `main.dart` with ProviderScope, MaterialApp.router
   - `config/` (env.dart, constants.dart)
   - `core/api/` (Dio client, JWT interceptor, token refresh)
   - `core/error/` (sealed Failure hierarchy)
   - `core/router/` (GoRouter with auth guard)
   - `core/theme/` (Material 3 setup)
   - `core/providers/` (session, auth state)
   - `core/widgets/` (BaseScreen, common dialogs)
   - `core/utils/` (validation utilities)
3. [ ] Write bootstrap instructions for auth feature:
   - Models (User, SessionToken — Freezed)
   - Services (AuthService interface + AuthServiceDjango)
   - Providers (auth notifier, session persistence)
   - Screens (login, register)
   - Widgets (login form, register form)
4. [ ] Write bootstrap instructions for project config:
   - `pubspec.yaml` with dependencies (use `^` ranges for flexibility)
   - `analysis_options.yaml` with strict linting
   - `build.yaml` for Freezed/Riverpod codegen
5. [ ] Ensure bootstrap references flutter-patterns.md for ongoing feature work after scaffolding

### Output
- `skills/execution/flutter-bootstrap.md` — new file

### Suggested Skills
- `skills/execution/flutter-patterns.md` (for pattern consistency)
- `skills/meta/writing-skills.md`

### Branch
`feature/flutter-stack-phase-2`

### Verification Checklist
- [ ] Interactive flow asks for all necessary config values
- [ ] Generated structure matches the project layout in flutter-patterns.md
- [ ] Auth feature follows the service interface pattern from patterns skill
- [ ] All files listed in brainstorm's bootstrap section are covered
- [ ] Instructions are step-by-step and unambiguous for Claude to execute

### Estimated Complexity: M

---

## Phase 3: Verification & Profile Update

### Objective
Update the Flutter verification checklist to align with new patterns, and update the profile to include the bootstrap skill.

### Input
- Completed `flutter-patterns.md` and `flutter-bootstrap.md` from Phases 1-2
- Existing: `skills/verification/verify-flutter.md`
- Existing: `profiles/flutter.txt`

### Tasks
1. [ ] Update `verify-flutter.md`:
   - Add checks for sealed Failure types (not generic exceptions)
   - Add checks for service interface pattern (abstract + concrete)
   - Add checks for @riverpod codegen (not hand-written providers)
   - Add checks for AsyncNotifier usage (forms, lists)
   - Add checks for Dio interceptor chain (auth, refresh, logging)
   - Tighten model checks (Freezed conventions from patterns skill)
   - Ensure checklist items map 1:1 to patterns skill sections
2. [ ] Update `profiles/flutter.txt`:
   - Add `skills/execution/flutter-bootstrap.md`
   - Verify all entries are correct and ordered logically
3. [ ] Review that all three files (patterns, bootstrap, verification) are consistent with each other

### Output
- Updated `skills/verification/verify-flutter.md`
- Updated `profiles/flutter.txt`

### Suggested Skills
- `skills/execution/flutter-patterns.md` (reference for alignment)

### Branch
`feature/flutter-stack-phase-3`

### Verification Checklist
- [ ] Every section in flutter-patterns.md has corresponding verification checks
- [ ] Profile installs cleanly via `install.sh --dry-run`
- [ ] No orphan references — all files in profile exist
- [ ] Verification checklist is actionable (clear pass/fail criteria per item)

### Estimated Complexity: S

---

## Dependencies
- Phase 2 depends on Phase 1 (bootstrap must match patterns)
- Phase 3 depends on Phases 1 & 2 (verification must cover both)
- No cross-repo dependencies — all work is within Polaris

## Risks & Open Questions
1. **Patterns file size** — 12 sections with code examples could get long. May need to be aggressive about conciseness to stay under token budget. Mitigation: write lean examples, no prose padding.
2. **Dependency versions** — Brainstorm left this open. Decision for Phase 2: use `^` ranges (e.g., `^2.5.0`) for flexibility. Document pinning as a project-level choice.
3. **Testing patterns depth** — How much test scaffolding in bootstrap? Decision: bootstrap creates one reference test for auth. Patterns skill documents the full testing approach.
4. **Platform targets** — Bootstrap should ask which platforms to enable. Default: iOS + Android.

## Cross-Repo Notes
- Backend contract changes needed: N
- Frontend integration summary required: N
- This is all Polaris-internal skill authoring
