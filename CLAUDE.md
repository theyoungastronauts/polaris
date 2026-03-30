# Polaris repo

This is a skills/agents/workflows repository for Claude Code. It gets installed into other projects via `install.sh`. You are working on the repo itself, not a consumer project.

## Structure

```
skills/          Markdown instruction files Claude loads for guidance
  planning/      Plan creation, scoping, brainstorming
  ux/            Product requirements, UX specification
  execution/     Stack-specific patterns (Django, Next.js, Flutter, React, Tailwind)
  verification/  Code review checklists per framework
  writing/       Prose quality, AI antipatterns
  meta/          Skills for authoring new skills
  memory/        Project context lifecycle (/remember, /recall)
  git/           Commit conventions, worktrees
agents/          Role definitions (planner, executor, reviewer, integrator)
workflows/       Multi-step orchestration docs
templates/       Fillable templates (integration summaries)
  context/       Context scaffold templates (ROUTER, decisions, conventions, patterns)
profiles/        .txt manifests + .claude.md snippets per stack
  _multi-stack.txt  Auto-added items for multi-stack installs
  *.claude.md       CLAUDE.md context snippets (one per stack, uses {directory} placeholder)
install.sh       Copies files into ~/.claude/ (global) or .claude/ (project)
context-pull.sh  Extracts Django backend context for frontend sessions
```

## Conventions

- Skills are markdown files — no code execution, just instructions for Claude
- Each skill should be self-contained: readable without needing other files
- Keep skills concise. Token cost matters — every line loads into context
- Heavy reference docs should use `cmd:` in profiles to install as on-demand slash commands (`.claude/commands/`) instead of always-loaded skills
- Profile lines: plain path = always loaded, `cmd:name=path` = on-demand `/name` command
- External/adapted skills: note source attribution in README.md table
- `install.sh` copies (not symlinks) so consumer projects are independent
- Checksum comparison detects stale installs — don't change file semantics without considering downstream staleness

## Adding a new skill

1. Create `.md` in the appropriate `skills/` subdirectory
2. Add it to relevant profiles in `profiles/*.txt`
3. If it's large (100+ lines of reference material), use `cmd:name=` in profiles
4. If adapted from external source, add to README.md attribution table
5. Follow the patterns in `skills/meta/writing-skills.md` for structure guidance

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

- Don't add runtime code — this repo is purely markdown instructions + shell scripts
- Don't create skills that depend on other skills being loaded (self-contained)
- Don't put project-specific context in skills — keep them generic/reusable
