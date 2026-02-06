# Skill: Plan and Scope

## Purpose
Guide the creation of a structured, phased implementation plan before any code is written.

## When to Use
At the start of any new feature, refactor, or project. Always plan before executing.

## Process

### 1. Clarify the Goal
- What is the end-user outcome?
- What are the constraints (time, tech, compatibility)?
- What already exists that we're building on?

### 2. Define the Scope
- List what IS in scope (be specific)
- List what is NOT in scope (be explicit — this prevents creep)
- Identify assumptions that need validation

### 3. Map Dependencies
- What existing code/APIs/services does this touch?
- Are there cross-repo dependencies (backend ↔ frontend)?
- What needs to exist before this can start?
- **Repo strategy:** Will this be a monorepo (single `fullstack` profile) or separate repos per concern (e.g., `django-api` + `nextjs`)? Ask the user — this affects how `/scaffold` creates sub-projects and how phases are organized.

### 4. Identify Risks
- What could go wrong?
- What are we unsure about technically?
- Where might the plan need to change?

### 5. Produce the Plan Document
Output a `plan.md` with this structure:

```markdown
# Plan: [Feature Name]

## Goal
One paragraph describing the desired outcome.

## Scope
### In Scope
- ...

### Out of Scope
- ...

## Phases
(See phase-breakdown.md skill for detailed phase structure)

### Phase 1: [Name]
- Objective:
- Deliverables:
- Estimated complexity: S/M/L

### Phase 2: [Name]
...

## Repo Strategy
Monorepo / Separate repos: [choice]
Sub-projects: [e.g., api (django-api), web (nextjs)]

## Dependencies
- ...

## Risks & Open Questions
- ...

## Cross-Repo Notes
- Backend contract changes needed: Y/N
- Frontend integration summary required: Y/N
```

## Key Principles
- Plans are living documents — update them as you learn
- Each phase should be independently reviewable (own branch, own PR)
- A plan that's too detailed upfront is as bad as no plan — aim for clarity on WHAT, flexibility on HOW
- If a phase has more than ~3 days of work, break it down further
