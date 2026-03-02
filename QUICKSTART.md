# Polaris Quickstart

Cheat sheet for scaffolding a new project. See [USAGE.md](USAGE.md) for full details.

---

## First-Time Setup (once)

- [ ] `./install.sh init` — saves repo path, adds `polaris` alias
- [ ] `source ~/.zshrc` — pick up the alias
- [ ] `polaris global --fresh` — install global skills + developer defaults
- [ ] `pip install axoniq` — (recommended) install Axon for structural code intelligence

## New Project

### 1. Initialize + Design

- [ ] `polaris new ~/prj/my-app` — creates project, selects stacks, installs context
- [ ] `cd ~/prj/my-app`

**Option A — brainstorm from scratch:**

- [ ] Open Claude Code session
- [ ] "Let's brainstorm [your idea] using the brainstorming skill"
- [ ] The agent already knows your stack — no need to re-explain it
- [ ] Iterate until design is solid
- [ ] Design saved to `docs/plans/YYYY-MM-DD-<topic>-brainstorm.md`

**Option B — bring existing design work:**

- [ ] Drop briefs, wireframes, sitemaps, flow diagrams into `docs/design/`
- [ ] Open Claude Code session
- [ ] "Review my design materials using the design-intake agent"
- [ ] Answer clarifying questions as the agent distills the artifacts
- [ ] Design doc saved to `docs/plans/YYYY-MM-DD-<topic>-design.md`

### 1b. Product Definition (optional, for UI features)

- [ ] `/prd` — formalize requirements into a structured PRD
- [ ] `/ux-spec` — run 6 UX passes (mental model, IA, affordances, cognitive load, states, flow integrity)
- [ ] Skip for backend-only features

### 2. Scaffold

- [ ] In the same session: "Let's scaffold the project using /scaffold"
- [ ] Confirm the scaffold plan (stacks, directory names)
- [ ] Claude creates subdirectories, git inits, bootstraps
- [ ] If Axon is installed, initial index runs automatically

### 3. Plan

- [ ] Start a **new** Claude session
- [ ] "Turn the design docs in docs/plans/ into a phased implementation plan"
- [ ] The planner reads the most structured artifact available: UX spec > PRD > brainstorm doc
- [ ] Review phases — small enough to review individually? Dependencies flow forward?
- [ ] `plan.md` saved to project root

### 4. Execute + Review (repeat per phase)

- [ ] `cd` into sub-project (e.g., `~/prj/my-app/api/`)
- [ ] Open Claude Code session
- [ ] `/execute` — picks up the plan, confirms the phase, implements on main
- [ ] When done, start a **new** Claude session
- [ ] `/verify` — checks the work against the plan, produces verification report
- [ ] Fix any FAILs, then move to next phase

**Or use autopilot (hands-off):**
- [ ] `/autopilot` — loops through all phases: implement → test → verify → commit
- [ ] Stops on FAIL — fix issues and `/autopilot N` to resume

### 5. Cross-Repo Handoff (if applicable)

- [ ] After API phases: "Generate an integration summary"
- [ ] Before web phases: `~/prj/polaris/context-pull.sh ../api`
- [ ] Then execute web phases with the integration context loaded

---

## Ongoing Development

**Single feature:** branch → `/execute` → `/verify` → PR → merge

**Parallel features:** use git worktrees (`skills/git/worktrees.md`)
