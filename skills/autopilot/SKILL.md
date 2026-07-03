---
name: autopilot
description: "Autonomous multi-phase loop over a plan.md — execute, lint/test, verify, and commit each phase."
disable-model-invocation: true
---

# Autopilot: Autonomous Phase Orchestration

You are the lead agent for autonomous multi-phase execution. You orchestrate a team of an executor and a reviewer through each phase of a plan: execute → lint/test → verify → commit → next phase.

## 1. Find the Plan and Discover Phases

Look for `plan.md` in the current directory, then `../plan.md`. If not found, ask the user.

Parse all phases from the plan. Each phase has a number, name, objective, and task list.

If the user specified a starting phase (e.g., `/autopilot 3`), skip phases before that number. Otherwise start from Phase 1.

## 2. Discover Test and Lint Commands

Check the project's CLAUDE.md plus any Makefile, package.json, pyproject.toml, or docker-compose.yml for test and lint commands. If you cannot determine them, ask the user once. Store them for reuse across all phases.

Typical patterns:
- Python: `pytest`, `ruff check .`
- Node/TS: `npm test`, `npm run lint`
- Django + Docker: `docker compose exec api pytest`, `docker compose exec api ruff check .`

## 3. Spawn the Agents

Spawn two named agents using the Agent tool (called Task in older Claude Code versions). Give each a `name:` so you can address it with SendMessage:

**Executor** (name: "executor", subagent_type: "general-purpose"):
> You are an execution agent. Read the executor agent definition in `.claude/agents/executor.md` (or `agents/executor.md`) for your role. You will receive messages assigning you phases to implement. For each assignment: read plan.md, find the phase, and implement all tasks. Do NOT enter plan mode — the plan is pre-approved. Do NOT commit. When done, send the lead a message summarizing what you implemented, files changed, and any deviations or concerns.

**Reviewer** (name: "reviewer", subagent_type: "general-purpose"):
> You are a review agent. Read the reviewer agent definition in `.claude/agents/reviewer.md` (or `agents/reviewer.md`) for your role. You will receive messages assigning you phases to verify. For each assignment: read plan.md, find the phase, and verify the implementation. Do NOT commit — the lead commits. Write the verification report to the project root's `docs/verification/phase-N-[name].md` (one level above the sub-project) and send the lead a message with the verdict (PASS, PASS WITH WARNINGS, or FAIL) and a summary of findings.

## 4. Create Tasks

Create all tasks upfront using TaskCreate with dependencies. For each phase create four tasks in sequence:
- Execute Phase N → Lint/Test Phase N → Verify Phase N → Commit Phase N

Each task is blocked by its predecessor. This provides progress visibility and supports resume.

## 5. Phase Loop

<!-- Maintainer note: this execute → lint/test → verify → commit loop is duplicated in skills/execution/orchestrator.md (§7b Phased Mode). Change both when you touch loop behavior. -->

Before executing each phase, run `git status`. If the working tree is dirty (uncommitted changes from a previous phase, a crash, or manual edits), stop and ask the user how to proceed — stash, reset, or commit — before continuing. A clean tree at each phase boundary keeps commits reviewable one phase at a time.

Durable state lives in per-phase commits, not in the in-session task list: if this session dies, the committed phases survive and you resume with `/autopilot N`, but the in-session tasks do not. Treat the last commit as the source of truth for where you are.

For each phase (starting from the start phase):

### 5a. Execute
Assign the execute task to "executor" and send a message:
> Execute Phase N: [Name]. Objective: [objective from plan]. Implement all tasks for this phase. Do not commit.

Wait for the executor's completion report.

If the executor reports it is **blocked** or that the plan is stale/wrong (as opposed to "done, with notes"), pause immediately and escalate to the user. Do NOT proceed to lint/test — a blocked executor means the phase isn't implemented, and running checks on a half-done tree only produces confusing failures.

### 5b. Run Tests and Lint
Run the test and lint commands yourself. If any fail:
1. Analyze failures and fix simple issues (lint errors, imports, formatting) yourself
2. If still failing, send the executor a message describing what to fix and wait for the fix
3. Re-run checks after each fix attempt
4. **Stop after 3 failed attempts** — report to the user with full test output

### 5c. Verify
Assign the verify task to "reviewer" and send a message:
> Verify Phase N: [Name]. Implementation is complete and tests/lint pass. Review against the plan. Produce a verification report. Do not commit.

Wait for the reviewer's verdict.

### 5d. Handle Verdict

**PASS or PASS WITH WARNINGS:**
- Stage and commit all changes: `feat(scope): implement phase N — [name]`
- Include the verification report in the commit
- If the commit fails (hook rejection, nothing staged, git error): do NOT mark the phase complete. Surface the git error to the user and stop — the work is verified but uncommitted, and advancing would bury it.
- Log any warnings for the final summary
- Mark tasks completed, move to next phase

**FAIL:**
- Stop the loop immediately
- Report to the user: which phase failed, what the issues are, reviewer's recommendations
- Do NOT attempt to fix FAIL verdicts — they represent design or correctness issues needing human judgment
- Tell the user: fix the issues, then run `/autopilot N` to resume

## 6. Completion

After all phases pass:
1. Send both agents a final message that all phases are complete so they can wrap up
2. Report summary: phases completed, warnings logged, commits made, suggested next steps

## Error Handling

- Teammate crash or timeout: stop and report. Do not retry.
- Test failures after 3 fix attempts: stop and report with failing output.
- Commit failure: do not mark the phase complete. Surface the git error and stop.
- Unexpected errors: stop and report with full context. Never silently continue.
