# Global Developer Defaults

## How to Work With Me

- **Ask before assuming.** If requirements are ambiguous, ask a clarifying question rather than guessing.
- **Plan before coding.** For anything beyond a trivial change, outline your approach before writing code.
- **Work in small steps.** Implement one thing at a time, verify it works, then move on.
- **Commit frequently.** Each commit should represent one logical change.
- **Read before modifying.** Understand the patterns already in use and follow them.
- **Don't refactor while building.** Note it and move on. Mixing refactoring with feature work makes both harder to review.

## Workflow Rules

- When executing phased implementation plans, start making code changes immediately. Do NOT spend the entire session exploring the codebase without producing output. If exploration is needed, timebox it to 2-3 minutes then begin implementation.
- Always run commands from the correct project directory. Before executing any shell command, verify the current working directory matches the target sub-project. Never mix files between sub-projects (e.g., frontend files into backend folder).

## Tech Stack

This project uses Python (Django/DRF) for backends and TypeScript (Next.js) for frontends, typically in a Docker Compose setup with Celery. Always assume this stack unless told otherwise.

## Communication

- Be direct and concise. Skip preamble.
- Lead with the what and why, not the thought process.
- If something is broken, say what's broken and how to fix it.
- When unsure, say so explicitly with what you'd need to become sure.

## Code Quality Defaults

- Write tests alongside implementation, not after.
- Handle errors explicitly — no silent failures, no bare excepts, no empty catch blocks.
- Prefer readability over cleverness.
- Use meaningful names. If you need a comment to explain what a variable is, rename it.
- Follow existing project conventions. Consistency beats preference.
- Don't leave dead code, TODOs without context, or commented-out blocks.

## Testing & Verification

After implementing any feature, always run the full test suite, linter, and type checker before reporting completion. Format: `pytest` (Python), `npm run test && npm run lint && npm run typecheck` (TypeScript/Next.js). Do not consider a phase complete until all checks pass.

## Django Bootstrap Checklist

When bootstrapping Django projects:
1. Verify PyPI package names before adding to requirements (e.g., `django-admin-auto-filters` vs actual name).
2. Ensure all apps have initial migrations before running entrypoint.
3. Check for port conflicts.
4. Test `wait-for-it.sh` with actual variable values.

## Frontend Testing Conventions

When writing React/Next.js tests:
1. Use `*ByRole` queries with `name` option instead of `*ByText` to avoid ambiguous matches.
2. Always wrap components using React `use()` with Suspense boundaries.
3. Ensure form labels are linked with proper `htmlFor`/`id` attributes.

## Debugging

- Gather evidence before proposing a fix. Read the error, check the code, understand the cause.
- Don't shotgun-fix by trying multiple things at once. Change one thing, test, iterate.
- If a fix works but you don't understand why, keep investigating.

## Project Context

- Start sessions with `/recall` to load relevant project context (architecture, decisions, conventions, patterns).
- Run `/intel` after first install to populate the context scaffold in `.claude/context/`.
- Use `/remember` after sessions to capture decisions, conventions, or patterns worth preserving.
- The context router at `.claude/context/ROUTER.md` maps task types to the right context files — load only what you need.

## Context Awareness

- Use `/compact` proactively when context is getting heavy.
- If you've lost track, re-read the plan or task description before continuing.
- When starting a new task, state what you understand the goal to be before diving in.
