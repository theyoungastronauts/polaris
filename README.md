# Polaris

A version-controlled collection of skills, agents, and workflows for AI-assisted development with Claude Code.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/theyoungastronauts/polaris.git ~/prj/polaris
cd ~/prj/polaris

# Initialize (saves repo location, adds 'polaris' alias to your shell)
./install.sh init
source ~/.zshrc  # or open a new terminal

# Install global skills (available in every Claude session)
polaris global

# Or with developer defaults in CLAUDE.md (recommended for first-time setup)
polaris global --fresh
```

After init, use the `polaris` alias for all commands:

```bash
# Install stack-specific skills in a project (interactive)
cd ~/prj/my-app
polaris project

# Or specify stacks directly
polaris project --stack django --stack nextjs

# Override default directories
polaris project --stack django:api --stack nextjs:client

# Standalone repo (not a monorepo) — defaults directory to "."
polaris project --stack django --standalone

# Add project-specific extras
polaris project --stack django --extra skills/misc/vfx.md

# Wipe existing skills and reinstall (switching stacks or starting fresh)
polaris project --clean --stack django --stack nextjs

# Check what's installed and if updates are available
polaris status
```

## Structure

```
polaris/
├── install.sh              # Installer script
├── context-pull.sh         # Cross-repo context extraction
├── skills/                 # Native Agent Skills — one dir per skill: skills/<name>/SKILL.md.
│   │                       # Frontmatter sets behavior: auto-trigger (description / paths glob)
│   │                       # or command-only (disable-model-invocation). ~51 skills.
│   └── misc/               # Project-specific skills (flat .md, not in any profile — e.g. vfx.md)
├── agents/
│   ├── planner.md          # Planning agent
│   ├── design-intake.md    # Distills docs/design/ artifacts into a design doc
│   ├── executor.md         # Code execution agent
│   ├── reviewer.md         # Verification/review agent
│   ├── integrator.md       # Cross-repo context agent
│   └── drift-detector.md   # Checks recent changes against documented conventions
├── templates/
│   ├── integration-summary.md
│   ├── claude-md-defaults.md   # Developer-defaults CLAUDE.md (used by `global --fresh`)
│   └── context/            # Context scaffold templates (ROUTER, decisions, conventions, patterns)
└── profiles/
    ├── global.txt              # Skills for ~/.claude/
    ├── django.txt              # Backend stack (+ django.claude.md snippet)
    ├── nextjs-fullstack.txt    # Backend stack: full-stack Next.js (+ snippet)
    ├── nextjs.txt              # Frontend stack, DaisyUI (+ nextjs.claude.md snippet)
    ├── nextjs-shadcn.txt       # Frontend stack, ShadCN UI (+ snippet)
    ├── nextjs-mui.txt          # Frontend stack, Material UI (+ snippet)
    ├── flutter.txt             # Frontend stack (+ flutter.claude.md snippet)
    ├── astro.txt               # Frontend stack (+ astro.claude.md snippet)
    └── _multi-stack.txt        # Auto-added for multi-stack installs
```

## External Skills

Some skills are adapted from popular open-source skill repos:

| Skill | Source | Location |
|-------|--------|----------|
| Writing Clearly | [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | `skills/writing-clearly/SKILL.md` |
| Brainstorming | [obra/superpowers](https://github.com/obra/superpowers) | `skills/brainstorming/SKILL.md` |
| Writing Skills (meta) | [obra/superpowers](https://github.com/obra/superpowers) | `skills/writing-skills/SKILL.md` |
| Tailwind v4 Design System | [wshobson/agents](https://github.com/wshobson/agents) | `skills/tailwind/SKILL.md` |
| React Best Practices | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `skills/react/SKILL.md` |
| Write as Human | [tropes.fyi](https://tropes.fyi) via [ossama.is](https://ossama.is) | `skills/write-as-human/SKILL.md` |
| Hook runtime (concept) | [affaan-m/ECC](https://github.com/affaan-m/ECC) | `hooks/` (reimplemented in shell) |

## Profiles

Stacks are composable — select a backend and one or more frontends during `polaris project`.

| Profile | Type | Use Case |
|---------|------|----------|
| `global` | — | Installed to ~/.claude/, available everywhere |
| `django` | backend | Django/DRF backend |
| `nextjs-fullstack` | backend | Full-stack Next.js (Drizzle, Postgres, Redis, BullMQ, Auth.js) — pair with a Next.js frontend profile to pick the UI library |
| `nextjs` | frontend | Next.js frontend (DaisyUI) |
| `nextjs-shadcn` | frontend | Next.js frontend (ShadCN UI) |
| `nextjs-mui` | frontend | Next.js frontend (Material UI) |
| `flutter` | frontend | Flutter mobile/web app |
| `astro` | frontend | Astro landing page / marketing site |

## On-Demand Commands

Some heavy reference docs are installed as slash commands instead of always-loaded skills. They only enter context when you invoke them.

| Command | What | Profiles |
|---------|------|----------|
| `/prd` | Generate and refine a product requirements document | global |
| `/ux-spec` | Create UX specification through 6 designer-mindset passes | global |
| `/ux-to-prompts` | Transform UX spec into build-order prompts for UI tools | global |
| `/execute` | Execute a phase of the plan | global |
| `/verify` | Verify a completed phase against the plan | global |
| `/autopilot` | Autonomous phase execution (execute → test → verify → commit loop) | global |
| `/orchestrator` | Flexible task orchestration (parallel waves, auto-phasing, model overrides) | global |
| `/scaffold` | Create project from a plan (git init, bootstrap, install stacks) | global |
| `/intel` | Generate/update project context scaffold (architecture, decisions, conventions) | global |
| `/remember` | Save a decision, convention, or pattern to the context scaffold | global |
| `/recall` | Load relevant project context at session start | global |
| `/reflect` | Session retrospective — bridges learnings into the context scaffold | global |
| `/write-as-human` | Strip AI writing patterns from prose | global |
| `/react` | React best practices (57 rules) | nextjs, nextjs-shadcn, nextjs-mui |
| `/tailwind` | Tailwind v4 design system | nextjs, nextjs-shadcn, astro |
| `/verify-nextjs-shadcn` | ShadCN-specific verification checklist (components.json, `cn()`, next-themes) | nextjs-shadcn |
| `/verify-nextjs-mui` | MUI-specific verification checklist (sx, Emotion SSR, Grid `size`) | nextjs-mui |
| `/django-bootstrap` | Django project scaffolding (Docker, Celery, split settings) | django |
| `/nextjs-bootstrap` | Next.js project scaffolding (App Router, DaisyUI, JWT auth) | nextjs |
| `/nextjs-shadcn-bootstrap` | Next.js project scaffolding (App Router, ShadCN UI, JWT auth) | nextjs-shadcn |
| `/nextjs-mui-bootstrap` | Next.js project scaffolding (App Router, Material UI, JWT auth) | nextjs-mui |
| `/nextjs-fullstack-bootstrap` | Full-stack Next.js scaffolding (Drizzle, Postgres, Redis, BullMQ, Auth.js) | nextjs-fullstack |
| `/flutter-bootstrap` | Flutter project scaffolding (Riverpod, go_router, dio) | flutter |
| `/astro-bootstrap` | Astro project scaffolding (Tailwind v4, DaisyUI, landing page) | astro |
| `/visual-feedback` | Agentation MCP workflow for browser-annotated UI fixes | nextjs, nextjs-shadcn, nextjs-mui, astro |

Command-only skills carry `disable-model-invocation: true` in their `SKILL.md` frontmatter — they don't auto-trigger and run as `/name`. Each Next.js variant now has its own bootstrap command (`/nextjs-bootstrap`, `/nextjs-shadcn-bootstrap`, `/nextjs-mui-bootstrap`) since a native skill's directory name is its command name.

## Axon Integration (Code Intelligence)

Polaris integrates with [Axon](https://github.com/harshkedia177/axon), a graph-powered structural analysis tool that indexes codebases into a knowledge graph. If installed, Axon provides MCP tools for call graphs, impact analysis, dead code detection, and execution flow tracing — giving agents structural awareness beyond text search.

**Setup:**

```bash
pip install axoniq          # or: uv add axoniq
axon analyze .              # Initial index
axon serve --watch          # MCP server with live re-indexing
```

The `/scaffold` command auto-detects Axon and runs initial indexing when creating new projects. If Axon is not installed, it warns but doesn't block.

**How agents use it:**

| Stage | Axon tools | Purpose |
|-------|-----------|---------|
| Planning | `axon_query`, `axon_context` | Explore structure, understand existing architecture |
| Execution | `axon_impact`, `axon_context` | Check blast radius before modifying symbols |
| Verification | `axon_detect_changes`, `axon_dead_code` | Map diffs to affected symbols, catch orphaned code |

See `skills/axon-code-intel/SKILL.md` for the full integration guide.

## Project Context

Polaris maintains a navigable context scaffold in `.claude/context/` so agents load only what's relevant per task — not a monolithic architecture file.

**The scaffold:**

| File | Purpose |
|------|---------|
| `ROUTER.md` | Maps task types to the right context files — read this first |
| `architecture.md` | Stack, structure, constraints, key entry points — generated by `/intel` (not a shipped template) |
| `decisions.md` | Lightweight ADRs — why things are the way they are |
| `conventions.md` | Naming, file organization, error handling norms |
| `patterns/` | Reusable solutions discovered during implementation (one file per pattern) |

**How it works:**

1. Run `/intel` after first install to populate the scaffold from codebase analysis
2. Start sessions with `/recall` to load context relevant to your task
3. Use `/remember` after sessions to capture new decisions, conventions, or patterns
4. Run `/reflect` at session end — it now bridges session learnings into the scaffold

The scaffold grows over time without growing token cost — agents read ROUTER.md (under 50 lines) and pull only the files relevant to their current task.

## Hooks (Optional Guardrails)

Everything else in Polaris is markdown that Claude *chooses* to follow. Hooks run deterministically at Claude Code's lifecycle events, so they reinforce the workflow even when a session drifts. They are **opt-in and project-scoped** — never installed by `polaris global` or `polaris project`.

```bash
polaris hooks install        # minimal profile into the current project
polaris hooks status         # profile, wiring, and script freshness
polaris hooks uninstall      # remove (keeps your own hooks)
```

The `minimal` profile is non-blocking lifecycle safety: a SessionStart nudge toward `.claude/context/`, a per-session edited-file accumulator, and a Stop-time summary of files touched. Requires `jq`. See [hooks/README.md](hooks/README.md) for details and the design bar every hook must clear.

> Heavier profiles (`standard`, `strict`) — batch format/typecheck, config protection, secret scanning, blocking behavior — are intentionally not shipped yet; they need dogfooding before becoming defaults.

## Workflow

See [USAGE.md](USAGE.md) for the complete walkthrough, or [QUICKSTART.md](QUICKSTART.md) for a cheat sheet.

**New project (MVP build):**

1. **Brainstorm** — Shape the idea in a root project folder
2. **Define** (optional) — Run `/prd` to formalize requirements, `/ux-spec` for UX foundations
3. **Plan** — Turn the design into a phased implementation plan
4. **Scaffold** — Create sub-project repos and install profiles
5. **Execute** — Implement each phase on main with the executor agent
6. **Review** — Verify each phase with the reviewer agent
7. **Repeat** — Move through phases until the MVP is complete

Or use `/autopilot` to run steps 4-6 hands-off — it loops through all phases automatically and stops on failure. For broader work that needs task queuing, parallel execution, or auto-phasing, use `/orchestrator` instead.

**Ongoing development:**

- Start sessions with `/recall` to load relevant project context
- Single feature → branch, execute, review, PR, merge
- After sessions, run `/remember` to capture decisions or patterns worth preserving
- Multiple independent features → use git worktrees for parallel work (see the `/worktrees` skill)

## Cross-Repo Context

For full-stack work with decoupled repos:

```bash
# From your frontend repo, pull backend context
~/prj/polaris/context-pull.sh ../backend-api

# Context lands in .claude/backend-context.md
# Claude Code will see it automatically
```

## How It Works

Running `./install.sh init` saves the repo location, adds a `polaris` shell alias, and merges required settings into `~/.claude/settings.json` — a tool-permission allowlist (including a blanket `Bash` allow for autonomous workflows), LSP plugins, and the agent-teams `env` flag. Your existing settings are preserved and init prints a summary of exactly what it asserted. Re-running `init` is safe and idempotent: it re-asserts Polaris's permission allowlist, `enabledPlugins`, and `env` entries (adding any that are missing) without removing anything you added. Requires `jq` (`brew install jq`).

Both `polaris global` and `polaris project` automatically generate a `CLAUDE.md` with references to all installed skills, agents, and commands. This is how Claude Code discovers your skills. By default it amends the existing CLAUDE.md (preserving your content); use `--fresh` with `polaris global` to start with a developer-defaults template, or `--no-claude-md` to skip generation entirely.

The install script **copies** files (not symlinks) so projects work independently across machines. A checksum comparison lets you see what's stale:

```bash
polaris status
# ✓  current: skills/django-patterns/SKILL.md
# ⚠  stale:   skills/verify-django/SKILL.md
# ⚠  orphan:  skills/custom-thing/SKILL.md (not in repo)
```

Update with:
```bash
polaris global --force
polaris project --stack django --stack nextjs --force
```

> **Upgrading from a pre-native-skills install:** run the same `--force` reinstall (`polaris global --force`, `polaris project --stack … --force`). It installs the new `skills/<name>/SKILL.md` directories and — via manifest diffing — removes the old flat `skills/<cat>/*.md` and `commands/*.md` files your previous install left behind, so no orphaned files remain. Exception: installs old enough to have no `.polaris-manifest.json` can't be diffed — run `polaris uninstall` first, then a fresh `polaris project`.

## Customization

- **Add a skill**: Create `skills/<skill-name>/SKILL.md` with `name`/`description` frontmatter. Add `disable-model-invocation: true` for command-only skills, or `paths: ["**/*.ext"]` to auto-trigger only on matching files. See the `writing-skills` skill.
- **Add a profile**: Create a `.txt` file in `profiles/` listing skill names (bare) and `agents/*.md` paths to include
- **Check your changes**: Run `./install.sh validate` — catches missing skills, duplicate names, and stack profiles without a CLAUDE.md snippet
- **Reference a skill in a profile**: List its bare directory name (e.g. `django-patterns`) on its own line; install copies the whole `skills/<name>/` dir to `.claude/skills/<name>/`
- **Add a project-specific skill**: Put it in `skills/misc/` and install with `--extra skills/misc/my-skill.md`. `skills/misc/` is intentionally user-specific and not wired into any profile — files there (e.g. the tracked `vfx.md`) are accepted personal/project exceptions, not shipped defaults.
- **Project overrides**: Edit installed files in your project's `.claude/` — they won't be overwritten unless you use `--force`
- **Add an agent**: Create a `.md` file in `agents/`
