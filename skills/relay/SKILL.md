---
name: relay
description: "Hand in-flight work to a fresh session instead of compacting, or pick up from a relay doc."
disable-model-invocation: true
---

# Relay

A steerable replacement for `/compact`. `/relay` writes a short doc capturing what the current work *is* and where it's headed. A fresh session reads that doc and derives everything else itself.

Compaction keeps the whole conversation, lossily, and the user has no say in what survives. A relay keeps only what a new session cannot recompute — and the user says what matters.

## The one rule

**A relay doc carries narrative and pointers. Never status.**

Status is branch state, what's deployed, what's committed, which tasks are open, whether tests pass. All of it is derivable in seconds, and all of it goes stale between writing the doc and reading it. A stale status claim is worse than no claim, because it still reads as authoritative.

Narrative is why this approach, what was tried and abandoned and why, what the user decided, what is deliberately out of scope. None of that is recoverable from the repo.

Write pointers, not states: the branch *name*, the file *paths*, the task *IDs*. The arriving session looks up what they currently contain.

| Write this | Not this |
|---|---|
| "work is on `feat/character-chat`" | "`feat/character-chat` is 3 commits ahead, uncommitted" |
| "the retry logic lives in `worker/queue.ts`" | "queue.ts is done and tested" |
| "tracked as Smitty #143" | "#143 is in progress, ~60% there" |
| "tried polling first — it deadlocked under concurrent writes, so we moved to the listener" | "polling didn't work" |

## Mode 1 — write (`/relay <steering note>`)

The argument is the user steering what carries forward ("focus on the webhook path", "next session is just the migration"). Weight the doc toward it. If there's no argument, ask what the next session is for before writing — one question, then write.

1. Determine the slug: `basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`.
2. Timestamp: `date +%m%d-%H%M`.
3. Write to `~/.claude/relays/<slug>-<timestamp>.md` (`mkdir -p` first).
4. Print the paste-ready line and nothing else after it.

Target under 40 lines. If it's longer, it's carrying status.

```markdown
# Relay — <slug> — <YYYY-MM-DD HH:MM>

**For the arriving agent:** this doc is narrative only. Derive current state
yourself — git, tasks, tests — before you act on anything here. Then state
your plan and wait for a go-ahead. Do not start work off this doc alone.

## What we're doing
<2-4 sentences. The goal and why it matters. Not a task list.>

## Where it stands
<Narrative only. "The listener is wired but nothing calls it yet." Never
"done/not done" percentages.>

## Tried and ruled out
<Approach, and the specific reason it failed. This is the highest-value
section — it's what stops the next session repeating the work.>

## Decisions made
<User rulings, with the reasoning. These are binding on the next session.>

## Next
<What the user steered toward, first. Then anything else queued.>

## Pointers
- branch: <name>
- files: <paths>
- tasks: <IDs>
- docs: <paths or URLs to specs, plans, reviews>

## Out of scope
<Things deliberately not being done, so the next session doesn't drift in.>
```

Then print exactly:

```
/relay ~/.claude/relays/<slug>-<timestamp>.md
```

The paste line must be the slash command, not a plain-English "read this file" — this skill is command-only, so an English sentence would never load it in the fresh session, and none of the resume discipline below would apply.

**Sanitize before writing.** No API keys, tokens, passwords, connection strings, or personal data. Reference them by name (`ANTHROPIC_API_KEY is set locally and on Vercel`), never by value.

## Mode 2 — resume (`/relay <path>`)

If the argument resolves to a readable file, this is resume mode.

1. Read the doc.
2. **Derive current state before trusting anything.** Branch, dirty files, recent commits, whether the named files exist and what they contain now, open tasks. The doc's pointers tell you where to look; they do not tell you what you'll find.
3. Report anything that contradicts the doc. Drift is the signal that matters — say so plainly.
4. State the plan in a few lines and **wait**. Do not start work. The user ended the last session deliberately; they get to aim this one.

## Housekeeping

Relays are disposable. When writing a new one, if `~/.claude/relays/` holds files older than 30 days, mention the count and offer to delete — don't delete unprompted.

## Common mistakes

- **Restating what's in the repo.** If it's greppable, link to it.
- **A checklist instead of a narrative.** Task lists live in the tracker. The doc explains what the tracker can't.
- **Writing status because it feels helpful.** It is the one thing guaranteed to be wrong on arrival.
- **The arriving session acting immediately.** A relay is a briefing, not an instruction.
- **Padding.** A short accurate relay beats a thorough one written when context was already exhausted.
