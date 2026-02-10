# Skill: Visual Feedback with Agentation MCP

## Overview
Use browser annotations to drive frontend fixes. Humans mark up the live page, Claude picks up annotations via MCP and resolves them — no copy-paste, no describing UI bugs in words.

## When to Use
- Fixing visual/layout issues on a running web app
- Iterating on UI with a human reviewer annotating in-browser
- Any frontend task where "point at the broken thing" beats describing it
- NOT for backend-only work, API logic, or non-visual changes

## Setup

Install and register with Claude Code:
```bash
npm install agentation-mcp
claude mcp add agentation -- npx agentation-mcp server
```

Verify configuration:
```bash
npx agentation-mcp doctor
```

The browser toolbar connects to an HTTP server (port 4747 default), which feeds annotations to Claude via MCP stdio.

## MCP Tools Available

| Tool | Purpose |
|------|---------|
| `agentation_list_sessions` | List active annotation sessions |
| `agentation_get_session` | Get annotations for a session |
| `agentation_get_pending` | Pending annotations for a session |
| `agentation_get_all_pending` | All pending across sessions |
| `agentation_acknowledge` | Mark annotation as seen |
| `agentation_resolve` | Mark annotation as fixed |
| `agentation_dismiss` | Dismiss an annotation |
| `agentation_reply` | Reply to an annotation thread |
| `agentation_watch_annotations` | Block until new annotations arrive |

## Workflow

1. Human opens the running app with the Agentation toolbar active
2. Human clicks elements and leaves annotations (fix / change / question / approve)
3. Annotations include CSS selectors and React component paths — use these to locate code
4. Fetch pending annotations, acknowledge them, make the fix
5. Mark resolved once the change is committed or verified

### Hands-Free Mode
Use `agentation_watch_annotations` in a loop to auto-process feedback as it arrives. Good for rapid iteration sessions where the human is continuously reviewing.

## Annotation Data
Each annotation includes:
- **Element selector** — CSS selector for the annotated DOM element
- **Component path** — React component tree path (when available)
- **Intent** — `fix`, `change`, `question`, or `approve`
- **Severity** — `blocking`, `important`, or `suggestion`
- **Comment** — Human's description of the issue

## Common Mistakes
- Ignoring severity — address `blocking` annotations before `suggestion`
- Not acknowledging annotations — the human can't tell you've seen them
- Resolving without verifying — mark resolved only after the fix is confirmed
- Using watch mode without a batch window — set a reasonable timeout to avoid thrashing
