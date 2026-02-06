# Skill: Commit Conventions

## Format
```
type(scope): concise description

[optional body — explain WHY, not WHAT]

[optional footer — references, breaking changes]
```

## Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding or updating tests
- `docs`: Documentation only
- `chore`: Build, CI, tooling changes
- `style`: Formatting, no code change

## Rules
- Subject line: imperative mood, lowercase, no period, max 72 chars
- Body: wrap at 72 chars, explain motivation and context
- Reference the plan/phase when applicable: `Part of plan: [feature-name] Phase 2`
- One logical change per commit — don't mix refactoring with features

## PR Description
```markdown
## What
Brief description of the change.

## Why
Context and motivation.

## Phase
[Plan name] — Phase N: [Phase title]

## Changes
- Key change 1
- Key change 2

## Testing
How this was tested.

## Integration Notes
Any cross-repo impacts or integration summary updates.
```
