# Polaris repo

This is a skills/agents/workflows repository for Claude Code. It gets installed into other projects via `install.sh`. You are working on the repo itself, not a consumer project.

## Structure

```
skills/          Native Agent Skills — one directory per skill: skills/<name>/SKILL.md
                 Frontmatter drives behavior: auto-trigger (description, optional
                 paths globs) or command-only (disable-model-invocation: true → /<name>)
  misc/          Project-specific skills (flat .md, not in any profile — e.g. vfx.md)
agents/          Role definitions (planner, executor, reviewer, integrator)
templates/       Fillable templates (integration summaries)
  context/       Context scaffold templates (ROUTER, decisions, conventions, patterns)
profiles/        .txt manifests + .claude.md snippets per stack
  _multi-stack.txt  Auto-added items for multi-stack installs
  *.claude.md       CLAUDE.md context snippets (one per stack, uses {directory} placeholder)
hooks/           Optional, opt-in session guardrails (the one place we ship code)
  scripts/       POSIX-friendly shell hooks run by Claude Code at lifecycle events
  *.json         Profile fragments merged into a project's .claude/settings.json
install.sh       Copies files into ~/.claude/ (global) or .claude/ (project)
context-pull.sh  Extracts Django backend context for frontend sessions
```

## Working artifacts (`docs/`)

`docs/plans/` and `docs/verification/` are Polaris's own working artifacts, not shipped content:

- `docs/plans/` — phased plans for work on this repo (e.g. review-fix runs). The planner/`/execute` flow reads these.
- `docs/verification/` — verification reports the reviewer/`/verify` flow writes when checking those phases.

Both are intentionally tracked as project history — keep them. They are never installed into consumer projects.

## Conventions

- Skills are markdown (SKILL.md + YAML frontmatter) — no code execution, just instructions for Claude
- Each skill should be self-contained: readable without needing other files
- Keep auto-triggering skills concise. Token cost matters — they load into context when they fire
- Heavy reference docs set `disable-model-invocation: true` in frontmatter so they only load when invoked as `/<name>` — never auto-trigger a 500-line reference
- Profile lines: bare `name` = the `skills/<name>/` directory; literal paths (`agents/…`, `templates/…`) are copied as-is
- External/adapted skills: note source attribution in README.md table
- `install.sh` copies (not symlinks) so consumer projects are independent
- Checksum comparison detects stale installs — don't change file semantics without considering downstream staleness

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with frontmatter: `name` (matches the directory), `description` (third-person trigger description), optional `paths` globs for file-scoped auto-triggering
2. Add the bare skill name to relevant profiles in `profiles/*.txt`
3. If it's heavy reference material (100+ lines), set `disable-model-invocation: true` so it's `/name`-only
4. If adapted from external source, add to README.md attribution table
5. Follow the patterns in the `/writing-skills` skill (`skills/writing-skills/SKILL.md`) for structure guidance

## Adding a new stack profile

1. Create `profiles/<name>.txt` with metadata headers:
   ```
   # stack: backend|frontend
   # label: Display Name
   # directory: default-dir
   ```
2. List files (relative to repo root), one per line
3. Comments with `#`, blank lines ignored
4. Create a companion `profiles/<name>.claude.md` snippet with `{directory}` placeholder
5. Add to README.md profiles table

## Shell scripts

- `install.sh` and `context-pull.sh` use `set -euo pipefail`
- `context-pull.sh` is Django-specific by design (patterns target serializers/views/models)
- Test install changes with `--dry-run` before running live

## What NOT to do

- Don't add runtime code outside `hooks/` — skills, agents, and workflows stay
  pure markdown. The one sanctioned exception is `hooks/` (opt-in shell guardrails
  Claude Code executes at lifecycle events); keep it POSIX-friendly, non-blocking,
  and never auto-installed by `global`/`project`
- Don't create skills that depend on other skills being loaded (self-contained)
- Don't put project-specific context in skills — keep them generic/reusable
