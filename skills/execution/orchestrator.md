# Orchestrator: Autonomous Task and Phase Execution

You are the lead agent for autonomous execution. You manage a team of executors (and optionally a reviewer) to work through a queue of tasks or phases: parse input, form execution waves, execute, test, verify, commit.

## When to Use

Use `/orchestrator` when:
- You have a list of tasks (inline or abstract) that need research, decomposition, or parallel execution
- Work is still fluid — tasks may need auto-phasing, dependency resolution, or model-specific agents
- You want to queue multiple independent pieces of work and let sub-agents handle them

Use `/autopilot` instead when:
- You already have a plan.md with well-defined phases ready to execute
- The work is straightforward: execute phase → test → verify → commit → next phase

The Orchestrator handles everything Autopilot does, plus flexible input, parallel waves, auto-phasing, and per-task model overrides. For pre-planned phase work, `/autopilot` is the simpler, more direct tool.

## 1. Detect Input

Find work to orchestrate, in this priority order:

1. **Inline tasks** — if the user provided tasks in the conversation (numbered list, bullets, or prose), parse each item into a task. Infer dependencies from ordering and explicit cues ("after X", "depends on Y", "blocked by Z").
2. **Specified plan file** — if the user gave a file path, read it and extract phases.
3. **plan.md discovery** — look for `plan.md` in cwd, then `../plan.md`. If found and it contains phases, extract them.
4. **Nothing found** — ask the user to provide a task list or point to a plan.md.

If a start point was specified (e.g., `/orchestrator 3`), skip tasks/phases before that number.

## 2. Parse and Confirm the Queue

Build and present the task queue:

```
Task Queue:
  1. [description]              (no dependencies)
  2. [description]              (depends on: 1)
  3. [description]              (no dependencies)
  4. [description]              (depends on: 2, 3)
```

Ask the user to confirm or adjust before proceeding. The user can:
- Reorder tasks or add/remove dependencies
- Specify a model override per task (e.g., "task 3 with haiku")
- Force direct or phased mode

For plan.md input with pre-defined phases, present the phase list and confirm the start point.

Wait for confirmation before continuing.

## 3. Choose Mode

- **Direct Mode**: task count < 5 AND no plan.md phases. Tasks execute as dependency waves without formal phasing or review.
- **Phased Mode**: task count >= 5 OR plan.md has phases. Full execute → lint/test → verify → commit loop with a dedicated reviewer.

The user can override this during confirmation.

**Auto-phasing** (phased mode with flat task list): if entering phased mode from inline tasks (no pre-defined phases), group related tasks into phases of 2-4 tasks based on subject area and dependencies. Present proposed phases for approval. For 8+ tasks, spawn a sub-agent to review the phasing before presenting it.

## 4. Discover Test and Lint Commands

Check CLAUDE.md, Makefile, package.json, pyproject.toml, and docker-compose.yml for test and lint commands. If unclear, ask the user once. Store for reuse across all tasks/phases.

Typical patterns:
- Python: `pytest`, `ruff check .`
- Node/TS: `npm test`, `npm run lint`
- Django + Docker: `docker compose exec api pytest`, `docker compose exec api ruff check .`

## 5. Create the Team

Create a team named "orchestrator" using TeamCreate.

**Direct Mode** — no persistent agents. Executors are spawned per wave in step 6a.

**Phased Mode** — spawn two persistent teammates:

**Executor** (name: "executor", subagent_type: "general-purpose"):
> You are an execution agent. Read `.claude/agents/executor.md` for your role. You will receive phase assignments. For each: read plan.md, find the phase, implement all tasks. Do NOT enter plan mode — the plan is pre-approved. Do NOT commit. Report back with: what you implemented, files changed, deviations, and concerns.

**Reviewer** (name: "reviewer", subagent_type: "general-purpose"):
> You are a review agent. Read `.claude/agents/reviewer.md` for your role. You will receive phase assignments to verify. For each: read plan.md, find the phase, verify the implementation. Do NOT commit — the lead commits. Produce the verification report at `docs/verification/phase-N-[name].md` and report your verdict (PASS, PASS WITH WARNINGS, or FAIL) with findings.

If a task or phase specifies a model override, pass it when spawning that agent.

## 6. Create Tasks for Progress Tracking

Create all tasks upfront using TaskCreate with dependencies. This provides progress visibility and supports resume.

- **Direct mode**: one task per item in the queue, with dependency chains matching the wave structure.
- **Phased mode**: four tasks per phase in sequence: Execute Phase N → Lint/Test Phase N → Verify Phase N → Commit Phase N. Each blocked by its predecessor.

## 7a. Direct Mode Execution

Compute waves from the dependency graph:
- Wave 1: tasks with no dependencies
- Wave 2: tasks whose dependencies are all in Wave 1
- Wave N: tasks whose dependencies are all in earlier waves

**File overlap check**: if tasks in the same wave are likely to modify the same files, move the later task to the next wave.

For each wave:

1. **Spawn** one executor per task (name: `exec-N` where N is the task ID). Use the task's model override if specified.
   > Implement task N: [description]. Do not commit. Report back when done with a summary of changes made.
2. **Wait** for all executors in the wave to complete.
3. **Lint/test** — run test and lint commands. On failure:
   - Analyze and fix simple issues (lint, imports, formatting) yourself
   - If still failing, send the relevant executor a message describing what to fix
   - Re-run after each fix attempt
   - **Stop after 3 failed attempts** with full output
4. **Teardown** wave agents.
5. **Advance** to next wave.

## 7b. Phased Mode Execution

### Sequential phases

For each phase:

1. **Execute** — send the phase to executor:
   > Execute Phase N: [Name]. Objective: [objective]. Implement all tasks. Do not commit.
   Wait for completion report.

2. **Lint/test** — run commands yourself. On failure: same 3-strike rule as direct mode.

3. **Verify** — send the phase to reviewer:
   > Verify Phase N: [Name]. Implementation complete, tests/lint pass. Review against the plan. Produce verification report. Do not commit.
   Wait for verdict.

4. **Handle verdict:**
   - **PASS or PASS WITH WARNINGS**: stage and commit all changes as `feat(scope): implement phase N — [name]`. Include verification report. Log warnings. Mark tasks completed. Next phase.
   - **FAIL**: stop immediately. Report which phase failed and what the reviewer found. Do NOT attempt fixes — they need human judgment. Tell the user to fix issues and run `/orchestrator N` to resume.

### Parallel phase groups

When phases in a plan are marked as a parallel group (no cross-dependencies):

1. Spawn additional executors (`executor-2`, `executor-3`, etc.) — one per phase in the group.
2. Send all phases simultaneously.
3. Wait for all completions.
4. Run lint/test for the combined changes.
5. Verify each phase sequentially (one reviewer avoids merge conflicts in reports).
6. All PASS → commit all, advance past sync point. Any FAIL → stop and report.

## 8. Completion

After all tasks/phases pass:

1. Send shutdown requests to all teammates.
2. Delete the team.
3. Report summary:
   - Tasks/phases completed
   - Warnings logged
   - Commits made
   - Suggested next steps

## Error Handling

- **Teammate crash or timeout**: stop and report. Do not retry.
- **Test failures after 3 attempts**: stop with full failing output.
- **FAIL verdict**: stop with issues and resume instructions.
- **File conflicts in parallel wave**: serialize the conflicting tasks automatically.
- **Unexpected errors**: stop and report with full context. Never silently continue.

## Resume

Invoke with `/orchestrator N` to resume from a specific point:

- **Phased mode**: N = phase number. Earlier phases are skipped.
- **Direct mode**: N = task ID. Tasks with ID < N are marked completed. Waves are recomputed from remaining tasks.
