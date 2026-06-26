#!/usr/bin/env bash
# Polaris hook: Stop
# Summarize the files touched since the last stop, then reset the accumulator.
# The Stop hook runs after each assistant response, so this prints only when
# edits actually happened that turn. Non-blocking; never fail the session.
#
# Output is emitted as JSON with a "systemMessage" field — the one hook output
# Claude Code shows to the *user*. Plain stdout would only reach the debug log.

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

session="$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null || echo nosession)"
store="${TMPDIR:-/tmp}/polaris-edited-${session}.txt"

[[ -f "$store" ]] || exit 0

sorted="$(sort -u "$store" 2>/dev/null || true)"
rm -f "$store"

[[ -z "$sorted" ]] && exit 0

count="$(printf '%s\n' "$sorted" | grep -c .)"

# Build a multi-line message in the current shell (here-string, not a pipe, so
# the accumulated value survives the loop).
message="Polaris: ${count} file(s) touched this turn:"
while IFS= read -r f; do
    [[ -n "$f" ]] && message="${message}"$'\n'"  - ${f}"
done <<< "$sorted"

# jq encodes newlines/quotes safely.
jq -n --arg m "$message" '{systemMessage: $m}'

exit 0
