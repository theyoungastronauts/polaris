# Scaffold: Design to Projects

## When to Use

After brainstorming is complete and you have a design doc. Scaffold creates the project
structure so the planner has real directories, installed packages, and boilerplate to
reference when building the implementation plan.

## Prerequisites

- A brainstorm/design doc exists (`docs/plans/*.md`)
- Stack context is already in CLAUDE.md (set up by `polaris new`)

## Process

### 1. Identify Sub-Projects from the Design

Read CLAUDE.md for the selected stacks and the design doc for what's being built.
Map each sub-project to a bootstrap command:

| Sub-project type | Stack flag | Bootstrap command |
|------------------|------------|-------------------|
| Django/DRF API | `--stack django` | `/django-bootstrap` |
| Next.js frontend | `--stack nextjs` | `/nextjs-bootstrap` |
| Flutter app | `--stack flutter` | (manual setup) |

### 2. Confirm with the User

Present the scaffold plan before creating anything:

```
Scaffold Plan:
  Root: ~/prj/my-app/
  Stacks (from CLAUDE.md):
    - Backend: Django → server/
    - Frontend: Next.js → web/

  Will create:
    - Subdirectories within the current project
    - git init each sub-project
    - Run bootstrap commands

  Parallel bootstrap: Yes (2 sub-projects, no shared code)
```

Let the user adjust names, add/remove stacks, or change directories before proceeding.

### 3. Gather Bootstrap Configuration

Before creating anything, collect all bootstrap inputs from the user so teammate agents
can run non-interactively. Bootstrap commands ask interactive questions — if multiple
agents prompt simultaneously, it's unusable.

**For each sub-project, ask the user for the required values upfront:**

Django bootstrap values:
- Service/directory name (e.g., `my_service`)
- Docker Compose project name (kebab-case, e.g., `my-service`)
- Database name (snake_case, e.g., `my_service`)
- Host port (default: `8000`)
- Cache key prefix (e.g., `myserv`)
- Heroku app name (if deploying, or skip)

Next.js bootstrap values:
- App name (e.g., `my-app`)
- Docker Compose project name (kebab-case, e.g., `my-app-web`)
- Host port (default: `3000`)
- Backend API port (default: `8000` — match the Django port above)
- Production domain (e.g., `myapp.com`)
- App display title (e.g., `My App`)
- Architecture mode: frontend-centric, SSR-centric, or combination

Use the design doc and project name to propose sensible defaults for most of these.
Present them as a table the user can confirm or override:

```
Bootstrap Configuration:

  Django (server/):
    Service name:    my_service      (from project name)
    Compose project: my-service
    Database:        my_service
    Host port:       8000
    Cache prefix:    myserv
    Heroku app:      (skip)

  Next.js (web/):
    App name:        my-app
    Compose project: my-app-web
    Host port:       3000
    API port:        8000            (matches Django above)
    Domain:          myapp.com
    Display title:   My App
    Architecture:    SSR-centric     (recommended for new projects)

  Look right? [Y/n]
```

### 4. Create and Initialize

For each sub-project:

```bash
mkdir -p {root}/{suffix}
cd {root}/{suffix}
git init
```

Naming convention: `{suffix}` = role (`api`, `web`, `mobile`, `admin`) as a subdirectory of the root.

### 5. Run Bootstrap Commands

When there are multiple sub-projects, bootstrap them in parallel using a team.
Sub-projects have no shared code at this stage, so there are no conflicts.

All configuration was gathered in step 3 — agents receive pre-filled values and
should not prompt the user for any bootstrap inputs.

**Parallel bootstrap (2+ sub-projects):**

1. Create a team named "scaffold" using TeamCreate
2. Spawn one agent per sub-project using the Task tool with `team_name: "scaffold"`:

   For each sub-project, spawn a general-purpose agent with the pre-filled config:
   > You are bootstrapping the {label} sub-project at {root}/{suffix}/.
   > Read the bootstrap skill at .claude/commands/{bootstrap_command}.md and follow it.
   > Use these pre-filled configuration values (do NOT prompt the user for these):
   >
   > {list all key=value pairs from step 3 for this sub-project}
   >
   > After bootstrap completes, run: git add . && git commit -m "chore: initial {label} scaffold"
   > Report back what was created.

3. Wait for all agents to complete
4. Send shutdown requests and delete the team

**Single sub-project (no team needed):**

1. Change into the sub-project directory
2. Invoke the bootstrap command (`/django-bootstrap` or `/nextjs-bootstrap`)
3. Use the pre-filled configuration values from step 3
4. After bootstrap completes, make an initial commit:
   ```bash
   git add . && git commit -m "chore: initial project scaffold"
   ```

### 6. Generate VS Code Workspace (Optional)

```json
{
  "folders": [
    { "path": ".", "name": "Planning" },
    { "path": "api", "name": "API" },
    { "path": "web", "name": "Web" }
  ]
}
```

Save as `{root}/{root-name}.code-workspace`.

### 7. Report Summary

```
Scaffold complete:
  ~/prj/my-app/              (project root)
  ~/prj/my-app/server/       (Django backend) -- ready
  ~/prj/my-app/web/          (Next.js frontend) -- ready
  ~/prj/my-app/my-app.code-workspace
```

Then suggest the next step:

```
Project is scaffolded. Next:

1. Start a NEW Claude session in this directory
2. Tell it: "Turn the design into a phased implementation plan"
   - The planner can now reference real project files and structure
3. Review the plan, then execute phase by phase
```

## Key Principles

- **Confirm before creating** -- always show the plan and get user approval first
- **Monorepo with subdirectories** -- stacks live as subdirectories in a single repo
- **Scaffold before planning** -- real project structure makes plans more concrete
- **Parallel when possible** -- bootstrap sub-projects concurrently using teams
- **Bootstrap commands do the heavy lifting** -- this skill orchestrates; the bootstrap commands handle details
