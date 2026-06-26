#!/usr/bin/env bash
# Polaris hook: PostToolUse (Edit|Write|MultiEdit)
# Record edited file paths into a per-session temp file so the Stop hook can
# summarize them. PostToolUse cannot block — this only observes.
# Never fail the session: degrade to a no-op when jq or the payload is missing.

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

session="$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null || echo nosession)"
file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"

[[ -z "$file" ]] && exit 0

store="${TMPDIR:-/tmp}/polaris-edited-${session}.txt"
printf '%s\n' "$file" >> "$store"

exit 0
