# Polaris Usage Guide

A step-by-step walkthrough for taking an idea from brainstorm to working application using the Polaris system. This assumes you've already run `./install.sh init` and `polaris global`.

---

## Phase 0: Project Setup

There are two ways to start, depending on whether you need a planning/brainstorming phase first.

### Path A: Brainstorm First (recommended for new projects)

Start with a root planning folder. This is just a plain directory — not a git repo. Brainstorm and plan here before creating any code repos.

```bash
mkdir ~/prj/my-app && cd ~/prj/my-app
```

Global skills (planning, brainstorming, writing) are already available via `polaris global`. No profile install needed — just open a Claude Code session and start brainstorming (Step 1 below).

Planning artifacts (`*-brainstorm.md`, `plan.md`) live in this folder as working files. They'll be copied into the actual project repos during scaffolding.

After planning is done, use `/scaffold` to create sub-project repos as subdirectories (Step 2b below). The scaffold command will create subdirectories, git init each, run bootstrap commands, and install the right profiles.

### Path B: Jump Into an Existing Project

If you already know what you're building and have a repo ready:

```bash
cd ~/prj/my-app
polaris project
# Interactive: select backend (Django) + frontend (Next.js)
# Or non-interactive:
polaris project --stack django --stack nextjs
```

**If the repo is a standalone stack** (not a monorepo with subdirectories), use `--standalone` to default the stack directory to `.` instead of the profile default (`server`, `web`, etc.):

```bash
cd ~/prj/my-backend-api
polaris project --stack django --standalone
```

This copies skills into `.claude/` (always loaded) and slash commands into `.claude/commands/` (loaded on demand via `/command-name`). Stacks are composable — select a backend and one or more frontends. The `nextjs` stack installs `/react` and `/tailwind` as on-demand commands to keep context light.

**If the project already has a `.claude/` directory** (from a previous Polaris install, manual setup, or another tool), use `--clean` to wipe existing skills before installing:

```bash
# Remove existing Polaris files and reinstall with new stacks
polaris project --clean --stack django --stack nextjs

# Also replace CLAUDE.md with a fresh defaults template
polaris project --clean --fresh --stack django --stack nextjs
```

`--clean` removes all Polaris-tracked files (using the manifest from a previous install). If there's no manifest, it removes the standard `.claude/` subdirectories (`skills/`, `agents/`, `workflows/`, `templates/`, `commands/`). Your `CLAUDE.md` content outside the Polaris markers is preserved; if it has custom content, a `.bak` backup is created.

Skip to Step 3 (Execute) if you already have a plan, or Step 1 if you want to brainstorm first.

### CLAUDE.md (auto-generated)

Running `polaris global` or `polaris project` automatically generates a CLAUDE.md with references to all installed skills, agents, and commands. This is how Claude Code discovers your skills.

- **Amend mode** (default): Adds/updates a Polaris section between `<!-- polaris:start -->` and `<!-- polaris:end -->` markers. Your own content outside these markers is preserved.
- **Fresh mode** (`polaris global --fresh`): Creates a complete CLAUDE.md with developer defaults + skills. Useful for first-time setup. Backs up existing file to `.bak` if it has custom content.
- **Skip** (`--no-claude-md`): Opt out of CLAUDE.md generation if you manage it manually.

You can add project-specific context (stack, conventions) above or below the Polaris markers:

```markdown
# Project: My App

## Stack
- Python 3.12, Django 5.1, DRF
- PostgreSQL

## Conventions
- ...

<!-- polaris:start -->
## Polaris Skills
...auto-generated...
<!-- polaris:end -->
```

---

## Step 1: Brainstorm

Open a Claude Code session in your project directory. This is a conversation, not code — you're shaping the idea.

**Start the session:**

```
You: I want to build [describe your idea]. Let's brainstorm this using the
     brainstorming skill in .claude/skills/planning/brainstorming.md
```

Claude will follow the brainstorming skill:

1. It reviews your project state (files, docs, existing code)
2. It asks you questions **one at a time** to refine the idea
3. It proposes 2-3 approaches with trade-offs and a recommendation
4. It presents the design in small sections (~200-300 words each), checking after each one

**Your job during brainstorming:**

- Answer honestly — push back if something doesn't feel right
- Apply YAGNI aggressively — if you're unsure whether you need it, you don't
- When Claude presents approaches, pick one and explain why (this becomes context later)

**Output:** A brainstorm document saved to `docs/plans/YYYY-MM-DD-<topic>-brainstorm.md`. Claude will suggest handing this off to the planner agent as the next step.

---

## Step 1b: Product Definition (optional)

For features with a user-facing interface, formalize requirements and design the UX before planning. Skip this step for backend-only or technical features.

### Generate a PRD

If you need to structure requirements beyond what the brainstorm captured:

```
You: /prd
```

Claude will follow the PRD skill to:

1. Generate a structured PRD with 7 sections (problem, demo goal, target user, core use case, functional decisions, UX decisions, data & logic)
2. Ask you for a clarification depth (5/10/20/35 questions)
3. Run an adaptive clarification pass, refining the PRD through targeted questions

**Output:** A PRD saved to `docs/plans/{topic}-prd.md`.

### Create a UX Specification

If the feature needs deliberate UX design:

```
You: /ux-spec
```

Claude will run 6 forced designer-mindset passes — no visual specs until all 6 are complete:

1. **Mental Model** — What does the user think is happening?
2. **Information Architecture** — What exists, how is it organized?
3. **Affordances** — What actions are obvious without explanation?
4. **Cognitive Load** — Where will the user hesitate?
5. **State Design** — How does the system talk back? (empty, loading, success, error)
6. **Flow Integrity** — Does this feel inevitable?

Only after the passes does it produce visual specifications.

**Output:** A UX spec saved to `docs/plans/{topic}-ux-spec.md`.

### Optional: Build-Order Prompts

If you want to feed the UX spec into external UI generation tools (v0, Bolt, Stitch):

```
You: /ux-to-prompts
```

This extracts atomic units from the UX spec, maps dependencies, and generates self-contained prompts in build order.

---

## Step 2: Plan

Once you have a design you're happy with (and optionally a PRD and UX spec), turn it into a structured implementation plan. **Start a new session** so the planner agent gets fresh context.

**Start the session:**

```
You: Turn the design docs in docs/plans/ into a phased implementation plan.
     Use the plan-and-scope and phase-breakdown skills.
```

The planner will automatically read any brainstorm docs, PRDs, and UX specs it finds. If a UX spec exists, it will extract implementation tasks from the state design and flow integrity passes.

Claude will produce a `plan.md` following the planning skills:

1. **Goal** — one paragraph on the desired outcome
2. **Scope** — what's in and what's explicitly out
3. **Phases** — each with objective, tasks, inputs, outputs, suggested skills
4. **Dependencies** — what needs to exist before each phase
5. **Risks** — what could go wrong

**Review the plan carefully.** This is the most leveraged moment in the workflow — a bad plan compounds into bad code. Look for:

- Are the phases small enough to review individually? (Target: 1-3 hours of Claude execution each)
- Do dependencies flow forward? (Phase 2 shouldn't depend on Phase 3)
- Is cross-repo work separated? (Backend phase → integration summary → frontend phase)
- Is anything missing from scope?

**Iterate** until the plan feels right. If you're in a git repo, commit it. If you're in a root planning folder (Path A), the plan will be copied into sub-project repos during scaffolding.

---

## Step 2b: Scaffold Sub-Projects (new projects only)

If you used Path A (brainstorm first) and need to create sub-project repos, use the `/scaffold` command.

**In the same session (or a new one) in the root planning folder:**

```
You: The plan is ready. Let's scaffold the sub-projects using /scaffold
```

Claude will follow the scaffold skill to:

1. Read the plan and identify what sub-projects are needed
2. Present a scaffold summary for your approval
3. Create subdirectories (e.g., `~/prj/my-app/server/`, `~/prj/my-app/web/`)
4. Git init the project
5. Run the appropriate bootstrap commands (`/django-bootstrap`, `/nextjs-bootstrap`)
6. Install Polaris stacks via `polaris project --stack django:server --stack nextjs:web`
7. `plan.md` stays at the project root
8. Optionally generate a VS Code workspace file

After scaffolding, the project has a single `.claude/` at the root with skills for all selected stacks. If Axon is installed (`pip install axoniq`), the scaffold also runs initial indexing for structural code intelligence.

**Skip this step** if you used Path B (existing project) or already have your repos set up.

---

## Step 3: Execute a Phase

For the initial MVP build, work directly on main — there's nothing to protect yet. Each phase builds on the last, and commits between phases give you natural review points.

Open a Claude Code session **in the sub-project directory.**

```bash
cd ~/prj/my-app/api
# Start Claude Code here
```

**Start the session:**

```
You: /execute
```

Claude will find the plan, ask which phase to execute, confirm, and start implementing:

1. Read the plan and identify Phase 1's objective, tasks, and inputs
2. Load the stack skills already installed by your profile (e.g. `django-patterns`, `commit-conventions`)
3. Implement each task in order
4. Write tests alongside implementation
5. Commit frequently with clear messages
6. If the phase produces an API, generate an integration summary

**Your job during execution:**

- Let Claude work, but stay engaged — review what it's doing
- If Claude asks a question, answer it (good sign — means it's not assuming)
- If you see it going off-plan, redirect early
- Don't let it gold-plate — if it's adding things not in the phase scope, pull it back

**Watch for these red flags:**

- Touching files outside the phase's scope
- Skipping tests ("I'll add those later")
- Making assumptions about other phases' work
- Not committing frequently enough

**After execution completes,** Claude will summarize what was done, list commits, flag any deviations, and suggest running `/verify` in a new session.

### Alternative: Autopilot (hands-off)

Instead of manually running `/execute` and `/verify` per phase, use `/autopilot` to loop through all phases automatically:

```
You: /autopilot
```

Autopilot spawns an executor and reviewer as teammates and orchestrates the full cycle for each phase: implement → lint/test → verify → commit. It stops immediately on a FAIL verdict so you can intervene.

To resume from a specific phase after fixing issues:

```
You: /autopilot 3
```

See `workflows/full-feature.md` for where this fits in the overall workflow.

---

## Step 4: Verify

Open a **new, separate Claude Code session** in the same directory. Fresh context is the point — the reviewer shouldn't inherit the executor's assumptions.

```bash
cd ~/prj/my-app/api
# Start a NEW Claude Code session
```

**Start the session:**

```
You: /verify
```

Claude will find the plan, identify the phase from recent git history, and systematically check:

1. Tests pass
2. Implementation matches the plan's acceptance criteria
3. Security (auth, validation, no data leaks)
4. Code quality (readable, tested, no dead code)
5. Scope (nothing extra, nothing missing)
6. Cross-repo contracts match (if applicable)

It produces a `verification-report.md` with a results table and verdict.

**The report will flag issues as:**

- **PASS** — looks good
- **WARN** — concern but not blocking
- **FAIL** — needs to be fixed before moving on

**If there are FAILs:** Fix them in this session or go back to step 3. Re-verify after fixes.

**If everything passes:** Move to the next phase.

---

## Step 5: Next Phase

Continue to the next phase in the same sub-project:

```
You: Execute Phase 2 of the plan.
```

Repeat the execute → verify cycle (Steps 3-4) for each phase until the sub-project is complete.

If there are multiple sub-projects (e.g., API then web), complete the API phases first, then move to the web sub-project:

```bash
cd ~/prj/my-app/web
# Start Claude Code here
```

---

## Cross-Repo Workflow (Backend + Frontend)

When a feature spans both repos, the flow is:

```
Backend phases  →  generates integration summary
                        ↓
Frontend phases  ←  consumes integration summary
```

The `integrator` agent and `cross-repo-context` skill manage this handoff.

**After completing a backend phase that adds/changes API endpoints:**

```
You: Generate an integration summary for the API changes in this phase.
     Use the integrator agent in .claude/agents/integrator.md
     and the cross-repo-context skill.
```

Claude will examine serializers, views, and permissions to produce a summary at `docs/integration/[feature-name].md` with endpoints, request/response shapes, auth requirements, and error codes.

**Before starting a frontend phase that consumes backend APIs:**

Pull backend context into the frontend using `context-pull.sh`:

```bash
# From the frontend sub-project
~/prj/polaris/context-pull.sh ../api
# Creates .claude/backend-context.md — Claude sees it automatically
```

Or copy the integration summary directly:

```bash
cp ../api/docs/integration/feature-name.md .claude/
```

**Start the frontend session:**

```
You: We're building the frontend for [feature]. Read the integration summary
     in .claude/ and the plan, then execute this phase.
     Use the executor agent and cross-repo-context skill.
```

---

## Ongoing Development

Once you have a working application and are adding new features:

### Single Feature

Just use a branch:

```bash
git checkout -b feature/notifications
# Start Claude Code, execute, review, PR, merge
```

### Multiple Independent Features in Parallel

Use git worktrees to work on unrelated features simultaneously without stashing or context switching. See `skills/git/worktrees.md` for the full setup.

```bash
cd ~/prj/my-app/api
git worktree add ../api-notifications -b feature/notifications
git worktree add ../api-billing -b feature/billing
# Each worktree is an isolated workspace with its own branch
```

---

## Quick Reference

| Step | What | Where | Agent/Skill |
|------|------|-------|-------------|
| 0 | Project setup | Root folder | `polaris global` / `polaris project` |
| 1 | Brainstorm | Root folder | `brainstorming` skill |
| 1b | Product definition (optional) | Root folder | `/prd` + `/ux-spec` commands |
| 2 | Plan | Root folder (new session) | `plan-and-scope` + `phase-breakdown` skills |
| 2b | Scaffold (new projects) | Root folder | `/scaffold` command |
| 3 | Execute | Sub-project (on main) | `/execute` command |
| 4 | Verify | Sub-project (new session) | `/verify` command |
| 3-5 | Autopilot (alternative) | Sub-project | `/autopilot` command (hands-off loop) |
| 5 | Next phase | Sub-project | Repeat from 3 |
| — | Cross-repo handoff | Backend → frontend | `integrator` agent + `cross-repo-context` skill |
| — | Ongoing: single feature | Any repo | Branch → execute → review → PR |
| — | Ongoing: parallel features | Any repo | Worktrees (see `skills/git/worktrees.md`) |

---

## Tips

- **Don't skip brainstorming.** Even for "simple" features, 10 minutes of design saves hours of rework.
- **Keep phases small.** If a phase feels too big to review in one sitting, split it.
- **Fresh sessions for verification.** The whole point is fresh eyes. Don't verify in the same session that wrote the code.
- **Commit the plan.** It's a living document — update it as you learn, but keep the history.
- **Integration summaries are contracts.** If the backend changes, update the summary before the frontend consumes it.
- **Use `/compact` in Claude Code** when context gets heavy during long execution phases.
- **Use `/react` or `/tailwind` when you need them.** These are on-demand commands — they only load into context when invoked, keeping your baseline token usage low.
- **Use `/visual-feedback` for UI iteration.** Install [Agentation](https://agentation.dev) in your project, and humans can annotate the live page in the browser while Claude picks up fixes via MCP. The bootstrap skills offer this as an optional step, or invoke `/visual-feedback` for the workflow.
- **Install Axon for structural awareness.** `pip install axoniq && axon analyze .` gives agents call graphs, impact analysis, and dead code detection. The MCP server (`axon serve --watch`) keeps the index current as you code. See `skills/execution/axon-code-intel.md`.
- **When in doubt, check the skills.** They're in `.claude/skills/` and `.claude/agents/` — read them if you forget the conventions.
