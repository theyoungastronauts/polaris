# Skill: Remember

Save a decision, convention, or pattern to the project's context scaffold.

## When to Use

Run `/remember <description>` when you want to persist something learned during a session:
- An architectural decision and its rationale
- A naming or structural convention discovered in the codebase
- A reusable pattern worth codifying for future work
- A freeform note that belongs in project context

## Process

### Step 1: Classify the Input

Read the user's description and classify it into one of three types:

| Type | Target File | Signal Words |
|------|------------|--------------|
| **Decision** | `.claude/context/decisions.md` | "decided", "chose", "switched to", "why we use", "tradeoff" |
| **Convention** | `.claude/context/conventions.md` | "always", "never", "naming", "file structure", "how we handle" |
| **Pattern** | `.claude/context/patterns/<name>.md` | "how to add", "the way we build", "standard approach for", "template for" |

If the classification is ambiguous, ask the user which type fits best. If it truly doesn't fit any category, default to Convention under "Project-Specific Rules".

### Step 2: Check for Duplicates

Read the target file and scan for similar existing entries:
- For decisions: check if the same topic is already covered (even with different wording)
- For conventions: check if the same rule exists under any category heading
- For patterns: check if a pattern file covering the same scenario already exists in `patterns/`

If a similar entry exists:
- Tell the user what you found
- Ask whether to **update** the existing entry or **add** alongside it
- If updating, preserve the original date and add an "Updated: YYYY-MM-DD" note

### Step 3: Format the Entry

**Decision format** (append under `## Entries` in decisions.md):
```markdown
### [Decision Title]
- **Date:** YYYY-MM-DD
- **Status:** Active
- **Rationale:** [Why this decision was made, including tradeoffs]
```

**Convention format** (append under the appropriate category in conventions.md):
```markdown
- [Convention]: [Example] — [Why, if not obvious]
```

Choose the right category heading: Naming, File Organization, Error Handling, Testing, or Project-Specific Rules. If none fit well, use Project-Specific Rules.

**Pattern format** (create a new file `.claude/context/patterns/<kebab-name>.md`):
```markdown
# [Pattern Name]
<!-- Added: YYYY-MM-DD -->

## When to Use
[Describe the situation where this pattern applies]

## Structure
[Show the file layout, class structure, or code skeleton]

## Example
[Reference an existing implementation: file path + brief explanation]

## Gotchas
[Common mistakes or non-obvious constraints]
```

Ask the user to fill in any sections you can't infer. At minimum, "When to Use" and "Structure" should have content.

### Step 4: Write the Entry

1. Read the target file
2. Insert the new entry in the correct location:
   - Decisions: above the `<!-- Add new decisions above this line -->` comment
   - Conventions: under the appropriate `##` category heading, above the `<!-- Add new conventions above this line -->` comment
   - Patterns: create new file in `.claude/context/patterns/`
3. Do NOT modify `## Manual Notes` or anything below it

### Step 5: Update ROUTER.md (Patterns Only)

If a new pattern file was created:

1. Read `.claude/context/ROUTER.md`
2. Add the pattern to the **Context Files** table with its purpose
3. If the pattern is relevant to specific task types, update the **Task Routing** table
4. Keep ROUTER.md under 50 lines

### Step 6: Confirm

Tell the user:
- What type was classified (decision/convention/pattern)
- Which file was written to (full path)
- The exact content that was added
- If a pattern was created, note that ROUTER.md was updated

## Scaffold Missing?

If `.claude/context/` doesn't exist, tell the user:

> Project context scaffold not found. Run `/intel` first to generate the scaffold structure, then use `/remember` to add entries.

Do not create the scaffold from scratch — `/intel` handles that.

## Common Mistakes

- **Writing to the wrong file** — decisions have rationale and tradeoffs, conventions are rules to follow, patterns are structural templates
- **Skipping deduplication** — always check before adding
- **Modifying Manual Notes** — never touch content below `## Manual Notes`
- **Creating trivial patterns** — a pattern file should describe something non-obvious and reusable, not a single-line convention
