---
name: wrap
description: "Close out a session — record what was learned, update any connected stores, and report what's left dirty."
disable-model-invocation: true
---

# Wrap

End-of-session close-out. Run at a milestone, when the work is worth recording and the session may not be returned to.

Two stores ship with Polaris, and both are local to this machine and this repo:

| Store | What lives there |
|---|---|
| Session memory — `~/.claude/projects/<path>/memory/` | Corrections, preferences, how to work with this user |
| Project context — `.claude/context/` | Decisions, conventions, patterns for *this* repo |

Anything beyond that — a cross-project knowledge base, an external task tracker — is an **extension**. See below. If none is installed, wrap is memory, context, and a repo report.

Not to be confused with [`relay`](../relay/SKILL.md): relay hands in-flight work to a fresh session mid-task. Wrap closes work out.

## Order matters

The command exists because the session may be abandoned. **Every unattended write happens before the first question is asked**, so walking away mid-wrap still leaves the durable stores current.

That splits the run into two phases, and the split is by risk:

| Phase 1 — written outright | Phase 2 — proposed, written on approval |
|---|---|
| Cheap to correct, and wrong entries are visible next session | Curated, or read by other people, or hard to undo |
| Session memory, project context | Commits |
| Whatever an extension declares safe | Whatever an extension declares curated |

Never invert it. A wrap that stops to ask before writing anything, and is then abandoned, has done nothing at all.

## Phase 1 — write

**Memory and project context.** Follow the [`reflect`](../reflect/SKILL.md) skill's process — scan, filter, classify, write. Read it rather than re-deriving the formats; it owns them.

One change: **write the surviving findings instead of proposing them.** Reflect proposes because it's used interactively. Wrap assumes nobody is watching. The filter carries the weight — anything failing reflect's four checks is discarded, not written and not mentioned.

**Then run each extension's Phase 1.**

## Phase 2 — propose

Run each extension's Phase 2, then handle the repo.

**Repo state.** Report what's uncommitted, untracked, or unpushed.

If the working tree holds one coherent change, propose a message and commit on approval. If it holds several unrelated changes, or work that's plainly half-finished, say so and commit nothing — close-out is exactly when unfinished work gets shipped by accident. Never push unless asked.

## Extensions

Some setups have stores that Polaris knows nothing about: a personal knowledge vault, a shared team wiki, an issue tracker, a status page.

**Wrap does not define those. It runs them.**

An extension is any available skill that owns such a store and documents a `## Close-out` section. Its description will say what it owns — a second brain, a vault, cross-project knowledge, a task tracker. At wrap time, check the available skills for one, read it, and follow its `## Close-out` section, honouring its Phase 1 / Phase 2 split.

If nothing is installed, skip both extension steps silently. Absence is the normal case, not an error.

### Writing a Close-out section

If you own such a skill, add a section like this and wrap will pick it up:

```markdown
## Close-out

Invoked by `/wrap`. Resolve the target first — never guess which record to write.

**Phase 1 (write):** <the cheap, correctable writes — capture files, completing
work that demonstrably finished>

**Phase 2 (propose, with exact text):** <the curated writes — status lines,
priority ordering, anything another person reads>
```

Two rules for any extension:

- **Resolve the target before writing.** If the current repo can't be matched to a record with confidence, capture to whatever the store's inbox equivalent is and say so. A confident write into the wrong record is worse than no write.
- **Never record what's derivable.** Branch state, deploy status, test results — all recomputable in seconds, all stale by the next read, and all still reading as authoritative. Record what happened and why.

## Report

Close with what landed, what's waiting on the user, and what's still dirty. A few lines.

If a store was skipped, say which and why. Silence implies it was covered.

## Common mistakes

- **Asking before writing.** Phase 1 must finish first. A blocked-then-abandoned wrap accomplishes nothing.
- **Committing to be tidy.** Half-finished work shipped at close-out is the failure this is most likely to cause.
- **Re-deriving reflect's formats, or an extension's.** Read the skill that owns them.
- **Treating a missing extension as a problem.** Most setups have none.
- **Reporting only successes.** What's still dirty is the most useful line in the summary.
