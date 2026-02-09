# Polaris

A version-controlled collection of skills, agents, and workflows for AI-assisted development with Claude Code.

## Quick Start

```bash
# Clone the repo
git clone <your-repo-url> ~/prj/polaris
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

# Add project-specific extras
polaris project --stack django --extra skills/misc/vfx.md

# Check what's installed and if updates are available
polaris status
```

## Structure

```
polaris/
├── install.sh              # Installer script
├── context-pull.sh         # Cross-repo context extraction
├── skills/
│   ├── planning/           # Plan creation, phase breakdown, brainstorming
│   ├── execution/          # Stack-specific patterns (Django, Next.js, Flutter, Tailwind, React)
│   ├── verification/       # Code review checklists per framework
│   ├── writing/            # Clear writing, AI antipatterns
│   ├── meta/               # Skills for authoring new skills
│   ├── git/                # Commit and PR conventions
│   └── misc/               # Project-specific skills (not in any profile)
├── agents/
│   ├── planner.md          # Planning agent
│   ├── executor.md         # Code execution agent
│   ├── reviewer.md         # Verification/review agent
│   └── integrator.md       # Cross-repo context agent
├── workflows/
│   └── full-feature.md     # End-to-end feature workflow
├── templates/
│   └── integration-summary.md
└── profiles/
    ├── global.txt          # Skills for ~/.claude/
    ├── django.txt          # Backend stack (+ django.claude.md snippet)
    ├── nextjs.txt          # Frontend stack (+ nextjs.claude.md snippet)
    ├── flutter.txt         # Frontend stack (+ flutter.claude.md snippet)
    └── _multi-stack.txt    # Auto-added for multi-stack installs
```

## External Skills

Some skills are adapted from popular open-source skill repos:

| Skill | Source | Location |
|-------|--------|----------|
| Writing Clearly | [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | `skills/writing/writing-clearly.md` |
| Brainstorming | [obra/superpowers](https://github.com/obra/superpowers) | `skills/planning/brainstorming.md` |
| Writing Skills (meta) | [obra/superpowers](https://github.com/obra/superpowers) | `skills/meta/writing-skills.md` |
| Tailwind v4 Design System | [wshobson/agents](https://github.com/wshobson/agents) | `skills/execution/tailwind-v4-design-system.md` |
| React Best Practices | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `skills/execution/react-best-practices.md` |

## Profiles

Stacks are composable — select a backend and one or more frontends during `polaris project`.

| Profile | Type | Use Case |
|---------|------|----------|
| `global` | — | Installed to ~/.claude/, available everywhere |
| `django` | backend | Django/DRF backend |
| `nextjs` | frontend | Next.js frontend |
| `flutter` | frontend | Flutter mobile/web app |

## On-Demand Commands

Some heavy reference docs are installed as slash commands instead of always-loaded skills. They only enter context when you invoke them.

| Command | What | Profiles |
|---------|------|----------|
| `/execute` | Execute a phase of the plan | global |
| `/verify` | Verify a completed phase against the plan | global |
| `/autopilot` | Autonomous phase execution (execute → test → verify → commit loop) | global |
| `/scaffold` | Create project from a plan (git init, bootstrap, install stacks) | global |
| `/react` | React best practices (57 rules) | nextjs |
| `/tailwind` | Tailwind v4 design system | nextjs |
| `/django-bootstrap` | Django project scaffolding (Docker, Celery, split settings) | django |
| `/nextjs-bootstrap` | Next.js project scaffolding (App Router, DaisyUI, JWT auth) | nextjs |

Profile lines prefixed with `cmd:` install to `.claude/commands/` instead of the default location:

```
cmd:react=skills/execution/react-best-practices.md
cmd:tailwind=skills/execution/tailwind-v4-design-system.md
cmd:django-bootstrap=skills/execution/django-bootstrap.md
cmd:nextjs-bootstrap=skills/execution/nextjs-bootstrap.md
```

## Workflow

See [USAGE.md](USAGE.md) for the complete walkthrough, or [QUICKSTART.md](QUICKSTART.md) for a cheat sheet.

**New project (MVP build):**

1. **Brainstorm** — Shape the idea in a root project folder
2. **Plan** — Turn the design into a phased implementation plan
3. **Scaffold** — Create sub-project repos and install profiles
4. **Execute** — Implement each phase on main with the executor agent
5. **Review** — Verify each phase with the reviewer agent
6. **Repeat** — Move through phases until the MVP is complete

Or use `/autopilot` to run steps 4-6 hands-off — it loops through all phases automatically and stops on failure.

**Ongoing development:**

- Single feature → branch, execute, review, PR, merge
- Multiple independent features → use git worktrees for parallel work (see `skills/git/worktrees.md`)

## Cross-Repo Context

For full-stack work with decoupled repos:

```bash
# From your frontend repo, pull backend context
~/prj/polaris/context-pull.sh ../backend-api

# Context lands in .claude/backend-context.md
# Claude Code will see it automatically
```

## How It Works

Running `./install.sh init` saves the repo location, adds a `polaris` shell alias, and merges required settings into `~/.claude/settings.json` — tool permissions, deny rules, and LSP plugins. Existing settings are preserved; only missing entries are added. Requires `jq` (`brew install jq`).

Both `polaris global` and `polaris project` automatically generate a `CLAUDE.md` with references to all installed skills, agents, and commands. This is how Claude Code discovers your skills. By default it amends the existing CLAUDE.md (preserving your content); use `--fresh` with `polaris global` to start with a developer-defaults template, or `--no-claude-md` to skip generation entirely.

The install script **copies** files (not symlinks) so projects work independently across machines. A checksum comparison lets you see what's stale:

```bash
polaris status
# ✓  current: skills/execution/django-patterns.md
# ⚠  stale:   skills/verification/verify-django.md
# ⚠  orphan:  skills/custom-thing.md (not in repo)
```

Update with:
```bash
polaris global --force
polaris project --stack django --stack nextjs --force
```

## Customization

- **Add a skill**: Create a `.md` file in the appropriate `skills/` subdirectory
- **Add a profile**: Create a `.txt` file in `profiles/` listing the files to include
- **Add an on-demand command**: Use `cmd:name=path/to/skill.md` in a profile to install as `/name` slash command
- **Add a project-specific skill**: Put it in `skills/misc/` and install with `--extra skills/misc/my-skill.md` (keeps it out of profiles)
- **Project overrides**: Edit installed files in your project's `.claude/` — they won't be overwritten unless you use `--force`
- **Add an agent**: Create a `.md` file in `agents/`
