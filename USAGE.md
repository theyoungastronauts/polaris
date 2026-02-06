# Polaris Usage Guide

A step-by-step walkthrough for taking an idea from brainstorm to merged PR using the Polaris system. This assumes you've already run `./install.sh init` and `polaris global`.

---

## Phase 0: Project Setup

There are two ways to start, depending on whether you need a planning/brainstorming phase first.

### Path A: Brainstorm First (recommended for new projects)

Start with a root planning folder. This is just a plain directory — not a git repo. Brainstorm and plan here before creating any code repos.

```bash
mkdir ~/prj/my-app && cd ~/prj/my-app
```

Global skills (planning, brainstorming, writing) are already available via `polaris global`. No profile install needed — just open a Claude Code session and start brainstorming (Step 1 below).

Planning artifacts (design docs, `plan.md`) live in this folder as working files. They'll be copied into the actual project repos during scaffolding.

After planning is done, use `/scaffold` to create sub-project repos (Step 2b below). The scaffold command will create sibling directories, git init each, run bootstrap commands, and install the right profiles. The sub-projects are the git repos — the root planning folder stays unversioned.

### Path B: Jump Into an Existing Project

If you already know what you're building and have a repo ready:

```bash
cd ~/prj/my-django-api
polaris project --profile django-api
# or: nextjs, flutter, fullstack
```

This copies skills into `.claude/` (always loaded) and slash commands into `.claude/commands/` (loaded on demand via `/command-name`). For example, the `nextjs` and `fullstack` profiles install `/react` and `/tailwind` as on-demand commands to keep context light.

Skip to Step 3 (Create Worktrees) if you already have a plan, or Step 1 if you want to brainstorm first.

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

**Output:** A design document saved to `docs/plans/YYYY-MM-DD-<topic>-design.md`.

---

## Step 2: Plan

Once you have a design you're happy with, turn it into a structured plan.

**In the same session (or a new one):**

```
You: Let's turn this design into a phased implementation plan. Use the 
     plan-and-scope and phase-breakdown skills.
```

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
3. Create sibling directories (e.g., `~/prj/my-app-api/`, `~/prj/my-app-web/`)
4. Git init each
5. Run the appropriate bootstrap commands (`/django-bootstrap`, `/nextjs-bootstrap`)
6. Install Polaris profiles via `polaris project --profile X --target Y`
7. Copy `plan.md` into each sub-project
8. Optionally generate a VS Code workspace file

After scaffolding, each sub-project is an independent repo with its own `.claude/` skills installed. Continue to Step 3 within each sub-project.

**Skip this step** if you used Path B (existing project) or already have your repos set up.

---

## Step 3: Create Worktrees

Now set up isolated workspaces for each phase. The `worktrees` skill handles creation, dependency installation, and baseline verification.

**Start the session:**

```
You: Set up worktrees for each phase in plan.md. Follow the worktrees skill
     in .claude/skills/git/worktrees.md
```

Claude will follow the worktrees skill:

1. Verify clean state on main
2. Create a worktree + branch per phase as sibling directories (`backend-phase-1`, etc.)
3. Auto-detect and install dependencies (Python/Node/Flutter)
4. Run tests in each worktree to confirm a clean baseline
5. Generate a VS Code `.code-workspace` file for the feature
6. Report readiness per worktree

Open the workspace file to see all phases in one VS Code window:

```bash
code ~/prj/my-project/my-feature.code-workspace
```

You should see something like:

```
✓ Worktree ready: ../my-app-phase-1
  Branch: feature/my-feature-phase-1
  Base: main (abc1234)
  Tests: 47 passing, 0 failures
  Ready to execute Phase 1
```

**After worktrees are created,** install the skills profile in each one:

```bash
cd ../my-app-phase-1
polaris project --profile django-api
# repeat for each worktree
```

**If tests fail before you've changed anything,** fix them on main first. Don't start a phase with a broken baseline.

---

## Step 4: Execute a Phase

Open a Claude Code session **in the phase worktree directory.** This is where code gets written.

```bash
cd ../my-app-phase-1
# Start Claude Code here
```

**Start the session:**

```
You: We're executing Phase 1 of the plan. Read plan.md and the executor agent 
     in .claude/agents/executor.md, then implement Phase 1.
```

Claude will follow the executor agent:

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

**After execution completes,** Claude should summarize what was done and flag any deviations from the plan.

---

## Step 5: Verify

Open a **new, separate Claude Code session** in the same worktree. Fresh context is the point — the reviewer shouldn't inherit the executor's assumptions.

```bash
cd ../my-app-phase-1
# Start a NEW Claude Code session
```

**Start the session:**

```
You: Review the code changes in this branch against plan.md Phase 1.
     Use the reviewer agent in .claude/agents/reviewer.md
     and the verification skill for this stack.
```

Claude will follow the reviewer agent:

1. Read the plan and identify Phase 1's acceptance criteria
2. Load the verification skill installed by your profile (e.g. `verify-django`, `verify-nextjs`)
3. Run through the verification checklist systematically
4. Run tests and linting
5. Check implementation against plan intent
6. Produce a `verification-report.md`

**The report will flag issues as:**

- **PASS** — looks good
- **WARN** — concern but not blocking
- **FAIL** — needs to be fixed before merging

**If there are FAILs:** Fix them in this session or go back to step 4. Re-verify after fixes.

**If everything passes:** Move to the next step.

---

## Step 6: Push and PR

The executor should have been committing throughout Step 4 using the `commit-conventions` skill. Verify and push:

```
You: Review the commits on this branch. Make sure they follow the
     commit-conventions skill. Then create a PR using the PR template
     from that skill.
```

Claude will:

1. Check commit messages follow conventional format (`type(scope): description`)
2. Amend or squash if needed
3. Push the branch
4. Create a PR with the standard template (What / Why / Phase / Changes / Testing / Integration Notes)

---

## Step 7: Human Review and Merge

This is you. Read the PR diff. Read the verification report. Merge when satisfied.

**After merge,** clean up the worktree. You can do this manually or ask Claude:

```
You: Phase 1 is merged. Clean up the worktree using the worktrees skill.
```

Claude will remove the worktree, delete the local branch, and pull main. The worktrees skill also supports batch cleanup when all phases are done.

---

## Step 8: Next Phase

If there are more phases, move to the next worktree and repeat from Step 4.

```bash
cd ../my-app-phase-2
# Start Claude Code here
```

If this phase depends on a previous phase (now merged), ask Claude to rebase first:

```
You: Phase 1 is merged. Rebase this branch onto main and verify the
     baseline tests still pass, per the worktrees skill.
```

Then proceed with execution (Step 4).

---

## Cross-Repo Workflow (Backend + Frontend)

When a feature spans both repos, the flow is:

```
Backend Phase  →  generates integration summary
                        ↓
Frontend Phase  ←  consumes integration summary
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

Pull backend context into the frontend worktree using `context-pull.sh`:

```bash
# From the frontend worktree (context-pull.sh is a separate script)
~/prj/polaris/context-pull.sh ../my-api-phase-1
# Creates .claude/backend-context.md — Claude sees it automatically
```

Or copy the integration summary directly:

```bash
cp ../my-api/docs/integration/feature-name.md .claude/
```

**Start the frontend session:**

```
You: We're building the frontend for [feature]. Read the integration summary
     in .claude/ and the plan, then execute this phase.
     Use the executor agent and cross-repo-context skill.
```

---

## Quick Reference

| Step | What | Where | Agent/Skill |
|------|------|-------|-------------|
| 0 | Project setup | Root folder | `polaris global` / `polaris project` |
| 1 | Brainstorm | Root folder | `brainstorming` skill |
| 2 | Plan | Root folder | `plan-and-scope` + `phase-breakdown` skills |
| 2b | Scaffold (new projects) | Root folder | `/scaffold` command |
| 3 | Create worktrees | Sub-project repo | `worktrees` skill |
| 4 | Execute | Phase worktree | `executor` agent + stack skills (from profile) |
| 5 | Verify | Phase worktree (new session) | `reviewer` agent + `verify-*` skill (from profile) |
| 6 | PR | Phase worktree | `commit-conventions` skill |
| 7 | Review + merge | GitHub / main repo | You |
| 8 | Next phase | Next worktree | `worktrees` skill (rebase) → repeat from 4 |
| — | Cross-repo handoff | Backend → frontend | `integrator` agent + `cross-repo-context` skill |

---

## Tips

- **Don't skip brainstorming.** Even for "simple" features, 10 minutes of design saves hours of rework.
- **Keep phases small.** If a phase feels too big to review in one sitting, split it.
- **Fresh sessions for verification.** The whole point is fresh eyes. Don't verify in the same session that wrote the code.
- **Commit the plan.** It's a living document — update it as you learn, but keep the history.
- **Integration summaries are contracts.** If the backend changes, update the summary before the frontend consumes it.
- **Use `/compact` in Claude Code** when context gets heavy during long execution phases.
- **Use `/react` or `/tailwind` when you need them.** These are on-demand commands — they only load into context when invoked, keeping your baseline token usage low.
- **When in doubt, check the skills.** They're in `.claude/skills/` and `.claude/agents/` — read them if you forget the conventions.