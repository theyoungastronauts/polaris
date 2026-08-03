---
name: wrap
description: "Close out a session — update memory, project context, the second brain, and tasks, then report what's left dirty."
disable-model-invocation: true
---

# Wrap

End-of-session close-out. Run at a milestone, when the work is worth recording and the session may not be returned to.

Three stores, not one. `/reflect` covers two of them and doesn't know the third exists:

| Store | What lives there |
|---|---|
| Session memory — `~/.claude/projects/<path>/memory/` | Corrections, preferences, how to work with the user |
| Project context — `.claude/context/` | Decisions, conventions, patterns for *this* repo |
| **The brain — `~/tybrain`** | Cross-project state: status, priorities, what happened |

Plus **Smitty**, the task store, which the brain links to but never mirrors.

Not to be confused with [`relay`](../relay/SKILL.md): relay hands in-flight work to a fresh session mid-task. Wrap closes work out.

## Order matters

**Do every auto-write before presenting a single proposal.** The user runs this because the session might be abandoned. Anything that can land unattended must already have landed by the time you stop to ask a question.

| Written without asking | Proposed, then written on approval |
|---|---|
| Session memory files + `MEMORY.md` pointer | Project note status line |
| `.claude/context/` entries | `context/this-week.md` |
| Vault `inbox/` capture | `context/priorities.md` |
| Completing tasks whose work is demonstrably done | Creating new tasks |
| | Any commit |

## 1. Resolve where the brain writes

Do this first — it determines everything in step 3. Skip to step 2 if `~/tybrain` doesn't exist.

The vault's project notes *are* the registry. Match the current repo to one by scanning `~/tybrain/projects/**/*.md` frontmatter:

- `path:` against the git toplevel or cwd (a monorepo sub-repo matches its parent's note)
- `aliases:` against the directory name

Take `smitty_project_id` from that note's frontmatter — step 4 needs it.

**No match?** Don't guess and don't write into an unrelated note. Capture to `inbox/` instead and say the project has no note yet, offering to create one.

**Already in `~/tybrain`?** The vault is the project. Skip the cross-repo resolution.

## 2. Memory and project context

Follow the [`reflect`](../reflect/SKILL.md) skill's process — scan, filter, classify, write. Read it rather than re-deriving the formats; it owns them.

One change: **write the surviving findings instead of proposing them.** Reflect proposes because it's used interactively. Wrap's whole point is that the user may not be there. The filter does the work — anything that fails reflect's four checks is discarded, not written and not mentioned.

## 3. The brain

Follow the `tybrain` skill for conventions — `~/.claude/skills/tybrain/SKILL.md` if installed, otherwise `~/tybrain/CLAUDE.md`, which is the full contract either way. Terse, dated, wikilinked. Match the surrounding tone; these files are read in Obsidian by a human.

**Write now:** durable cross-project knowledge that has no home yet → `inbox/YYYY-MM-DD-<slug>.md`. Don't over-organize on capture; triage happens at review.

**Propose, with the exact text you'd write:**

- **Project note status line** — a fresh `**Status (as of YYYY-MM-DD):**` paragraph on the matched note, replacing the previous one rather than stacking. This is the main thing that keeps the vault true.
- **`context/this-week.md`** — amend this project's focus bullet only if the week's picture actually changed. A shipped feature changes it; a refactor doesn't.
- **`context/priorities.md`** — only when what the user should look at first has moved. This is the most curated file in the vault; most sessions leave it alone.

Never write status into the vault that's derivable in seconds — branch state, what's deployed, test results. Record what happened and why, and let the next session look up the rest.

## 4. Smitty tasks

The dashboard is only useful if it's true. Auth and endpoints are in `~/tybrain/CLAUDE.md`.

**Complete now:** anything this session demonstrably finished. `PATCH /api/tasks/tasks/<id>` with `{"status":"done"}`.

**Gotchas that cost a round-trip otherwise:** status is one of `open`, `in_progress`, `done`, `archived` — `completed` is rejected by a CHECK constraint. Booleans are integers, not JSON booleans. `is_priority: 1` means "shows in the priorities view" and should track `context/priorities.md`, while the `priority` field is ranking within a project.

**Propose:** new tasks for commitments made this session (with `project_id` from step 1), and any demotion or block, dated and naming the why.

## 5. Repo state

Report what's uncommitted, untracked, or unpushed.

If the working tree holds one coherent change, propose a message and commit on approval. If it holds several unrelated changes, or work that's plainly half-finished, say so and commit nothing — closing out is exactly when unfinished work gets shipped by accident. Never push without being asked.

## 6. Leave the vault clean

If the vault was touched, commit it (`git -C ~/tybrain`) with a short capture message. Don't push unless asked.

## Report

Close with what landed, what's waiting on the user, and what's still dirty. A few lines. If a store was skipped — no vault match, no context scaffold, no Smitty — say which and why, rather than staying silent and implying it was covered.

## Common mistakes

- **Asking before writing.** The auto-write half must complete first. A wrap that blocks on a question and gets abandoned has done nothing.
- **Writing derived state into the vault.** It rots between the write and the next read, and still reads as authoritative.
- **Stacking a new status line under the old one.** Replace it. Two dated statuses means the reader has to work out which is live.
- **Guessing the project note.** No frontmatter match means capture to `inbox/`, not a best guess into a neighbouring note.
- **Mirroring tasks into markdown.** Tasks live in Smitty. The vault links to them.
- **Re-deriving reflect's or tybrain's formats.** Read those skills.
