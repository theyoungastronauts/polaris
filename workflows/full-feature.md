# Workflow: Full Feature

## Overview
End-to-end workflow for implementing a feature from plan to merged PR.

## Steps

### 1. Plan
```bash
# Start a Claude session with the planner agent
# Input: feature description / requirements
# Output: plan.md
```
- Use the `planner` agent
- Skills loaded: `plan-and-scope`, `phase-breakdown`
- Review and iterate on the plan before proceeding

### 2. Setup Worktrees
```bash
# Follow the worktrees skill (skills/git/worktrees.md)
# From your repo root:
REPO_NAME=$(basename $(pwd))
FEATURE="[name]"

for PHASE in 1 2 3; do
  git worktree add "../${REPO_NAME}-phase-${PHASE}" -b "feature/${FEATURE}-phase-${PHASE}"
done
```
- Each worktree: install dependencies, verify tests pass (clean baseline)
- Copy `plan.md` into each worktree (or reference from main)
- Install relevant skills: `./install.sh project --profile [stack]`

### 3. Execute (per phase)
```bash
# In the phase worktree, start a Claude session
# Load: executor agent + stack skills
# Input: plan.md (focused on this phase)
# Output: implemented code + tests
```
- Use the `executor` agent
- Skills loaded: stack-specific patterns + commit-conventions
- Commit frequently within the phase

### 4. Verify (per phase)
```bash
# NEW Claude session in the same worktree
# Load: reviewer agent + stack verification skill
# Input: the code changes + plan.md
# Output: verification-report.md
```
- Use the `reviewer` agent
- Skills loaded: `verify-[framework]`
- Fix any FAIL items, re-verify if needed

### 5. Commit & PR
```bash
# Ensure all commits follow conventions
# Create PR with context from plan
git push origin feature/[name]-phase-N
# Create PR using the PR template from commit-conventions
```

### 6. Human Review & Merge
- Review the PR + verification report
- Merge when satisfied
- Clean up worktree: `git worktree remove ../[repo]-phase-N` (see worktrees skill for batch cleanup)

### 7. Cross-Repo Handoff (if applicable)
- If this phase produced API changes, ensure integration summary is generated
- Copy or commit the integration summary where the frontend can access it
- Start the frontend phase with the integration summary as input

## Tips
- Don't skip the planning step — it saves time overall
- Keep phases small enough to review in one sitting
- The verification step catches things you'd miss in self-review
- Update the plan as you learn — it's a living document
