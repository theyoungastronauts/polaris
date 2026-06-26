# Polaris Hooks

Optional, opt-in session guardrails for Claude Code. Hooks are the one place
Polaris ships **executable code** (POSIX-friendly shell) instead of markdown.
They are never installed by `polaris global` or `polaris project` — you opt in
explicitly, per project.

## Why hooks

The rest of Polaris guides Claude through instructions it *chooses* to follow.
Hooks run deterministically at lifecycle boundaries, so they can reinforce the
workflow even when a session drifts. Every Polaris hook must earn its place by
answering yes to at least one of:

1. Does it preserve context or prevent context loss?
2. Does it stop the agent from weakening the project to make itself pass?
3. Does it catch mistakes earlier than a human review would?
4. Does it reinforce the Polaris workflow?
5. Does it avoid adding always-loaded context?

If a proposed hook can't, it doesn't ship.

## Install

```bash
polaris hooks install                 # minimal profile, current git project
polaris hooks install --dry-run       # preview without writing
polaris hooks install --target DIR    # a specific project
polaris hooks status                  # profile, wiring, and script freshness
polaris hooks uninstall               # remove Polaris hooks (keeps your own)
```

Requires `jq` (used to edit `settings.json` safely without clobbering your own
hooks or other settings keys).

### What install does

- Copies the hook scripts to `<project>/.claude/hooks/` and marks them
  executable.
- Merges the profile's hook entries into `<project>/.claude/settings.json`.
  Re-running is idempotent — old Polaris entries are stripped and re-added, so
  no duplicates. Your own hooks and other settings are left untouched.
- Records the active profile and installed files under the `hooks` key of
  `.claude/.polaris-manifest.json`.

Scripts are referenced via `$CLAUDE_PROJECT_DIR`, so no absolute paths are baked
into your settings. Start a new Claude Code session to load the hooks.

> `polaris uninstall` (the project-wide removal) does not touch hooks — manage
> them with `polaris hooks uninstall`.

## Profiles

### `minimal` (the only profile today)

Lifecycle safety with almost no friction. Non-blocking; nothing here can stop a
tool call or fail a session.

| Hook | Event | Behavior | Audience |
|---|---|---|---|
| `polaris-session-start.sh` | `SessionStart` | If `.claude/context/ROUTER.md` exists, nudge toward `/recall` and skimming it before editing. | **Agent** — injected into context, not a visible chat message (this is how SessionStart stdout works). |
| `polaris-edited-file-accumulator.sh` | `PostToolUse` (Edit\|Write\|MultiEdit) | Record edited file paths to a per-session temp file, then reset at Stop. Observe only. | None — silent. |
| `polaris-stop-summary.sh` | `Stop` | Deduped summary of files touched that turn. Silent on turns with no edits. | **You** — emitted as JSON `systemMessage`, the one hook output Claude Code shows to the user. |

> **Output visibility matters.** For most events, hook stdout only reaches the
> debug log. `SessionStart` stdout is added to the agent's context (so the agent
> acts on the nudge, but you don't see a message). To surface text to the *user*,
> a hook must print JSON with a `systemMessage` field — which is what the Stop
> summary does. Verify any hook fired with `/hooks` or `claude --debug`.

Future profiles (`standard`, `strict`) are intentionally **not** shipped yet —
batch format/typecheck, config protection, secret scanning, and blocking
behavior need dogfooding before they become defaults.

## Design notes

- **Never fail the session.** Every script exits `0` even on bad input, and
  degrades to a no-op when `jq` or the payload is missing.
- **User-visible output uses `systemMessage`.** Plain stdout would vanish into
  the debug log; the Stop summary emits JSON so you actually see it.
- **POSIX-friendly.** No bash-4 features (e.g. `mapfile`) — these run under
  macOS's stock bash 3.2.
- **Stack-agnostic.** The minimal profile does not run formatters or type
  checkers, so it works across every Polaris stack profile.
