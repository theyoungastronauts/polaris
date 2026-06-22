#!/usr/bin/env bash
# Polaris hook: SessionStart
# If the project has a context scaffold, nudge the agent toward it.
# stdout from a SessionStart hook is injected into the session context,
# so keep this short. Never fail the session.

proj="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
router="$proj/.claude/context/ROUTER.md"

if [[ -f "$router" ]]; then
    echo "Polaris: project context is scaffolded at .claude/context/. If this task touches existing code, run /recall <task> and skim ROUTER.md before editing."
fi

exit 0
