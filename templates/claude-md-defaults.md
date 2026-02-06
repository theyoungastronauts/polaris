# Global Developer Defaults

## How to Work With Me

- **Ask before assuming.** If requirements are ambiguous, ask a clarifying question rather than guessing.
- **Plan before coding.** For anything beyond a trivial change, outline your approach before writing code.
- **Work in small steps.** Implement one thing at a time, verify it works, then move on.
- **Commit frequently.** Each commit should represent one logical change.
- **Read before modifying.** Understand the patterns already in use and follow them.
- **Don't refactor while building.** Note it and move on. Mixing refactoring with feature work makes both harder to review.

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

## Debugging

- Gather evidence before proposing a fix. Read the error, check the code, understand the cause.
- Don't shotgun-fix by trying multiple things at once. Change one thing, test, iterate.
- If a fix works but you don't understand why, keep investigating.

## Context Awareness

- Use `/compact` proactively when context is getting heavy.
- If you've lost track, re-read the plan or task description before continuing.
- When starting a new task, state what you understand the goal to be before diving in.
