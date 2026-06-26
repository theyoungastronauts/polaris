#!/usr/bin/env bash
# Polaris hook: Stop
# Summarize the files touched since the last stop, then reset the accumulator.
# The Stop hook runs after each assistant response, so this prints only when
# edits actually happened that turn. Non-blocking; never fail the session.

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

session="$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null || echo nosession)"
store="${TMPDIR:-/tmp}/polaris-edited-${session}.txt"

[[ -f "$store" ]] || exit 0

sorted="$(sort -u "$store" 2>/dev/null || true)"
rm -f "$store"

[[ -z "$sorted" ]] && exit 0

count="$(printf '%s\n' "$sorted" | grep -c .)"
echo "Polaris: ${count} file(s) touched this turn:"
printf '%s\n' "$sorted" | while IFS= read -r f; do
    [[ -n "$f" ]] && echo "  - $f"
done

exit 0
