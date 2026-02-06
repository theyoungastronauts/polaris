# Workflow: Full Feature

## Overview
End-to-end workflow for implementing a feature from plan to merged code.

## Steps

### 1. Plan
- Use the `planner` agent
- Skills loaded: `plan-and-scope`, `phase-breakdown`
- Output: `plan.md` with phased tasks
- Review and iterate on the plan before proceeding

### 1b. Scaffold (new projects only)
If this is a new project with sub-repos to create:
- Use `/scaffold` from the root planning folder
- Creates sub-project directories, git inits, installs profiles
- Skip this step for features in existing repos

### 2. Execute — MVP Build

For initial builds where you're taking a plan from zero to working application, work directly on main. No branches or worktrees needed — there's nothing to protect yet.

Repeat for each phase:

**Execute:**
- Start a Claude session in the sub-project
- Tell it: "Execute phase N of the plan"
- The executor agent reads plan.md, implements, and commits as it goes

**Review:**
- Start a NEW Claude session in the same directory
- Tell it: "Review phase N against the plan"
- The reviewer agent checks the work and produces a verification report
- Fix any FAIL items, re-verify if needed

**Commit and move on:**
- Commits happen on main as the executor works
- Between phases, the commit history provides a natural review point
- If this phase produced API changes, generate the integration summary for frontend phases
- Continue to the next phase

### 3. Execute — Ongoing Feature Work

Once you have a working application and are building new features on top of it:

**Single feature:** check out a branch, execute, review, PR, merge. Simple.

**Multiple independent features in parallel:** use git worktrees (see `skills/git/worktrees.md`). Each feature gets its own worktree so you can switch between them without stashing or losing context. This is where worktrees earn their keep.

## Tips
- Don't skip the planning step — it saves time overall
- Keep phases small enough to review in one sitting
- The verification step catches things you'd miss in self-review
- Update the plan as you learn — it's a living document
