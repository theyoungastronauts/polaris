# Polaris Quickstart

Cheat sheet for scaffolding a new project. See [USAGE.md](USAGE.md) for full details.

---

## First-Time Setup (once)

- [ ] `./install.sh init` — saves repo path, adds `polaris` alias
- [ ] `source ~/.zshrc` — pick up the alias
- [ ] `polaris global --fresh` — install global skills + developer defaults

## New Project

### 1. Brainstorm

- [ ] `mkdir ~/prj/my-app && cd ~/prj/my-app`
- [ ] Open Claude Code session
- [ ] "Let's brainstorm [your idea] using the brainstorming skill"
- [ ] Iterate until design is solid
- [ ] Brainstorm saved to `docs/plans/YYYY-MM-DD-<topic>-brainstorm.md`

### 2. Plan

- [ ] Start a **new** Claude session
- [ ] "Turn the design into a phased implementation plan"
- [ ] Review phases — small enough to review individually? Dependencies flow forward?
- [ ] `plan.md` saved to project root

### 3. Scaffold

- [ ] In the same session: "Let's scaffold the sub-projects using /scaffold"
- [ ] Confirm the scaffold plan (sub-project names, profiles)
- [ ] Claude creates subdirectories, git inits, bootstraps, installs profiles

### 4. Execute + Review (repeat per phase)

- [ ] `cd` into sub-project (e.g., `~/prj/my-app/api/`)
- [ ] Open Claude Code session
- [ ] `/execute` — picks up the plan, confirms the phase, implements on main
- [ ] When done, start a **new** Claude session
- [ ] `/verify` — checks the work against the plan, produces verification report
- [ ] Fix any FAILs, then move to next phase

### 5. Cross-Repo Handoff (if applicable)

- [ ] After API phases: "Generate an integration summary"
- [ ] Before web phases: `~/prj/polaris/context-pull.sh ../api`
- [ ] Then execute web phases with the integration context loaded

---

## Ongoing Development

**Single feature:** branch → `/execute` → `/verify` → PR → merge

**Parallel features:** use git worktrees (`skills/git/worktrees.md`)
