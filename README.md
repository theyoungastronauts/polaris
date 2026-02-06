# Polaris

A version-controlled collection of skills, agents, and workflows for AI-assisted development with Claude Code.

## Quick Start

```bash
# Clone the repo
git clone <your-repo-url> ~/prj/polaris
cd ~/prj/polaris

# Initialize (saves repo location to ~/.polaris.conf)
./install.sh init

# Install global skills (available in every Claude session)
./install.sh global

# In a project directory, install stack-specific skills
cd ~/prj/my-django-api
~/prj/polaris/install.sh project --profile django-api

# Add project-specific extras not in any profile
~/prj/polaris/install.sh project --profile django-api --extra skills/misc/vfx.md

# Check what's installed and if updates are available
~/prj/polaris/install.sh status
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
    ├── django-api.txt
    ├── nextjs.txt
    ├── flutter.txt
    └── fullstack.txt
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

| Profile | Use Case |
|---------|----------|
| `global` | Installed to ~/.claude/, available everywhere |
| `django-api` | Django/DRF backend projects |
| `nextjs` | Next.js frontend projects |
| `flutter` | Flutter mobile/web app projects |
| `fullstack` | Projects spanning backend + frontend |

## On-Demand Commands

Some heavy reference docs are installed as slash commands instead of always-loaded skills. They only enter context when you invoke them.

| Command | What | Profiles |
|---------|------|----------|
| `/react` | React best practices (57 rules) | nextjs, fullstack |
| `/tailwind` | Tailwind v4 design system | nextjs, fullstack |
| `/django-bootstrap` | Django project scaffolding (Docker, Celery, split settings) | django-api, fullstack |
| `/nextjs-bootstrap` | Next.js project scaffolding (App Router, DaisyUI, JWT auth) | nextjs, fullstack |

Profile lines prefixed with `cmd:` install to `.claude/commands/` instead of `.claude/polaris/`:

```
cmd:react=skills/execution/react-best-practices.md
cmd:tailwind=skills/execution/tailwind-v4-design-system.md
cmd:django-bootstrap=skills/execution/django-bootstrap.md
cmd:nextjs-bootstrap=skills/execution/nextjs-bootstrap.md
```

## Workflow

See [workflows/full-feature.md](workflows/full-feature.md) for the complete flow:

1. **Plan** — Use planner agent to scope and phase the work
2. **Branch** — Create git worktrees per phase
3. **Execute** — Implement with executor agent + stack skills
4. **Verify** — Review with reviewer agent + verification skill
5. **PR** — Commit with conventions, create PR
6. **Merge** — Human review and merge

## Cross-Repo Context

For full-stack work with decoupled repos:

```bash
# From your frontend repo, pull backend context
~/prj/polaris/context-pull.sh ../backend-api

# Context lands in .claude/polaris/backend-context.md
# Claude Code will see it automatically
```

## How It Works

Running `install.sh init` also merges required settings into `~/.claude/settings.json` — tool permissions, deny rules, and LSP plugins. Existing settings are preserved; only missing entries are added. Requires `jq` (`brew install jq`).

The install script **copies** files (not symlinks) so projects work independently across machines. A checksum comparison lets you see what's stale:

```bash
./install.sh status
# ✓  current: skills/execution/django-patterns.md
# ⚠  stale:   skills/verification/verify-django.md
# ⚠  orphan:  skills/custom-thing.md (not in repo)
```

Update with:
```bash
./install.sh global --force
./install.sh project --profile django-api --force
```

## Customization

- **Add a skill**: Create a `.md` file in the appropriate `skills/` subdirectory
- **Add a profile**: Create a `.txt` file in `profiles/` listing the files to include
- **Add an on-demand command**: Use `cmd:name=path/to/skill.md` in a profile to install as `/name` slash command
- **Add a project-specific skill**: Put it in `skills/misc/` and install with `--extra skills/misc/my-skill.md` (keeps it out of profiles)
- **Project overrides**: Edit files in your project's `.claude/polaris/` — they won't be overwritten unless you use `--force`
- **Add an agent**: Create a `.md` file in `agents/`
