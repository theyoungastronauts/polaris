# Scaffold: Plan to Projects

## When to Use

After planning is complete in a root project folder and you need to create sub-projects
as separate repos (e.g., API backend + web frontend).

## Prerequisites

- A finalized `plan.md` (or `docs/plans/*.md`) exists and has been reviewed
- You know what sub-projects are needed and what stack each uses

## Process

### 1. Identify Sub-Projects from the Plan

Read the plan and map each sub-project to a Polaris profile and bootstrap command:

| Sub-project type | Profile | Bootstrap command |
|------------------|---------|-------------------|
| Django/DRF API | `django-api` | `/django-bootstrap` |
| Next.js frontend | `nextjs` | `/nextjs-bootstrap` |
| Flutter app | `flutter` | (manual setup) |
| Fullstack (mono) | `fullstack` | both bootstrap commands |

### 2. Confirm with the User

Present the scaffold plan before creating anything:

```
Scaffold Plan:
  Root: ~/prj/my-app/
  Sub-projects:
    1. ~/prj/my-app/api/   (django-api profile)
    2. ~/prj/my-app/web/   (nextjs profile)

  Will create:
    - Subdirectories within the current project
    - git init each
    - Run bootstrap commands
    - Install Polaris profiles
    - Generate VS Code workspace file
```

Let the user adjust names, add/remove sub-projects, or change profiles before proceeding.

### 3. Create and Initialize

For each sub-project:

```bash
mkdir -p {root}/{suffix}
cd {root}/{suffix}
git init
```

Naming convention: `{suffix}` = role (`api`, `web`, `mobile`, `admin`) as a subdirectory of the root.

### 4. Run Bootstrap Commands

For each sub-project with a bootstrap command:

1. Change into the sub-project directory
2. Invoke the bootstrap command (`/django-bootstrap` or `/nextjs-bootstrap`)
3. Use plan context to suggest sensible placeholder values
4. After bootstrap completes, make an initial commit:
   ```bash
   git add . && git commit -m "chore: initial project scaffold"
   ```

### 5. Install Polaris Profiles

```bash
polaris project --profile {profile} --target {root}/{suffix}
```

### 6. Copy Plan to Sub-Projects

Each sub-project needs plan context for the executor agent:

```bash
cp {root}/plan.md {root}/{suffix}/plan.md
```

Or reference it from each sub-project's `CLAUDE.md`:
```markdown
## Plan
See ../plan.md for the implementation plan.
```

### 7. Generate VS Code Workspace (Optional)

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

### 8. Report Summary

```
Scaffold complete:
  ~/prj/my-app/          (planning root)
  ~/prj/my-app/api/      (django-api) -- ready
  ~/prj/my-app/web/      (nextjs) -- ready
  ~/prj/my-app/my-app.code-workspace
```

Then present the next steps, filled in with the actual project names, phases, and profiles:

```
What to do next — one phase at a time:

1. Open a Claude session in the first sub-project (e.g. api/)
2. Tell it: "Execute phase 1 of the plan"
   - The executor agent reads plan.md, implements, and commits on main
3. When phase 1 is done, start a NEW Claude session in the same directory
4. Tell it: "Review phase 1 against the plan"
   - The reviewer agent checks the work and produces a verification report
5. Fix any issues, then move on to phase 2

Work directly on main during the initial build — there's nothing to
protect yet. Commits between phases give you natural review points.
```

## Key Principles

- **Confirm before creating** -- always show the plan and get user approval first
- **Subdirectories, separate repos** -- sub-projects live inside the root as subdirectories
- **One profile per sub-project** -- each gets exactly one stack profile
- **Plan travels with the project** -- copy plan.md so executor sessions have context
- **Bootstrap commands do the heavy lifting** -- this skill orchestrates; the bootstrap commands handle details
