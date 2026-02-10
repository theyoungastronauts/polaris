# Session Reflection

Capture what you learned this session into persistent memory.

## When to Use

Run `/reflect` at the end of a productive session — especially when:
- You corrected Claude's approach or preferences
- You hit a tricky bug and found the root cause
- You established or discovered project conventions
- You repeated a workflow pattern multiple times

Skip for quick sessions or trivial changes.

## 1. Scan the Session

Review the conversation history. Look for four categories:

**Corrections** (highest signal)
- Times the user redirected your approach
- Suggestions the user rejected and what they wanted instead
- Explicit preferences ("always do X", "never do Y")

**Debugging Insights**
- Root causes that weren't obvious from the error
- Framework gotchas or environment quirks
- Diagnostic sequences that worked

**Patterns**
- Repeated workflows worth codifying
- File organization or naming conventions
- Tool preferences or configurations

**Conventions**
- Architectural patterns found in the codebase
- Implicit project rules not documented elsewhere
- Integration patterns between services

## 2. Filter Ruthlessly

Each candidate must pass ALL four checks:

1. **Stable?** — Will this recur? One-off decisions don't need memory.
2. **Already documented?** — Check CLAUDE.md, existing memory files, project docs. Don't duplicate.
3. **Actionable?** — "The API is complex" is useless. "Always pass X header when calling Y endpoint" is useful.
4. **Correctly scoped?** — Is this global (all projects) or project-specific?

Discard anything that fails any check.

## 3. Propose Updates

For each surviving finding, present:

```
**Category:** Correction | Debugging | Pattern | Convention
**Scope:** Global | Project: <name>
**File:** <target memory file, e.g. preferences.md, debugging.md>
**Action:** Add | Update | Remove

> The exact text to write

**Evidence:** What happened in the session that produced this
```

Group by scope (global first, then project), then by file.

## 4. Write Approved Changes

Only write what the user explicitly approves.

1. Read the target memory file (create if it doesn't exist)
2. Add or update content, keeping the file organized by topic
3. Keep entries concise — one to three lines per insight

## Memory Organization

**Global** (`~/.claude/memory/` or `~/.claude/projects/<path>/memory/`):
- `MEMORY.md` — High-priority items, always loaded (keep under 200 lines)
- Topic files (`debugging.md`, `preferences.md`, etc.) — Detailed notes linked from MEMORY.md

**Project** (`.claude/memory/`):
- Same structure, scoped to the project

Organize by topic, not by date. Use `##` headers to group related items:

```markdown
## Git Preferences
- Always use conventional commits with scope
- Prefer small, focused commits over batched changes

## Django Patterns
- Use get_object_or_404 over manual try/except in views
- Always add related_name to ForeignKey fields
```

## What NOT to Save

- Session-specific context (current task, temporary state)
- Information already in CLAUDE.md or project docs
- Speculative conclusions from limited evidence
- Generic best practices any developer would know
- Anything that contradicts established project conventions
