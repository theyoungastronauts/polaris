#!/usr/bin/env bash
# Polaris hook: Stop
# Summarize the files touched since the last stop, then reset the accumulator.
# The Stop hook runs after each assistant response, so this emits only when
# edits actually happened that turn. Non-blocking; never fail the session.
#
# Plain stdout from a Stop hook is NOT surfaced back into the session, so the
# summary is returned as JSON via hookSpecificOutput.additionalContext.

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

session="$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null || echo nosession)"
store="${TMPDIR:-/tmp}/polaris-edited-${session}.txt"

[[ -f "$store" ]] || exit 0

sorted="$(sort -u "$store" 2>/dev/null || true)"
rm -f "$store"

[[ -z "$sorted" ]] && exit 0

count="$(printf '%s\n' "$sorted" | grep -c .)"

summary="Polaris: ${count} file(s) touched this turn:"
while IFS= read -r f; do
    [[ -n "$f" ]] && summary+=$'\n'"  - $f"
done <<< "$sorted"

jq -n --arg ctx "$summary" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $ctx
  }
}'

exit 0
