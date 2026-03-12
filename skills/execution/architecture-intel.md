# Skill: Architecture Intel

## Overview
Extract and maintain a persistent architectural summary of a codebase in `.claude/architecture.md`. Eliminates cold-start context loss across sessions by documenting stack, decisions, patterns, constraints, and conventions in a file Claude loads automatically.

## When to Use
- First session on a new-to-you project
- After major refactors, dependency upgrades, or architectural shifts
- Periodically (every few weeks) to keep the file current
- When onboarding a new stack or sub-project

Do NOT use for: small bug fixes, routine feature work where architecture.md already exists and is current.

## Process

### Step 1: Detect Mode

Check if `.claude/architecture.md` exists:

- **Does not exist** → First Run mode (full analysis)
- **Exists** → read the `Last updated` date from the header comment
  - If user passed `--full` → Full Refresh mode
  - Otherwise → Incremental mode

### Step 2: Check Axon Availability

Run `axon_list_repos` to check if the current repo is indexed.

- **Axon available** → use the Axon analysis path (faster, more structural)
- **Axon unavailable** → use the file-read analysis path (still effective, just more manual)

Inform the user which path you're taking.

### Step 3: Analyze the Codebase

**With Axon:**
1. `axon_query` with broad concept terms — "authentication", "error handling", "data models", "routing", "middleware" — to identify the major patterns in use
2. `axon_context` on key entry points (main URL conf, root app component, main router, etc.) to map the layer structure
3. `axon_cypher` for structural queries when needed — find all classes following a pattern, identify service layers, locate middleware chains
4. Read package manifests (requirements.txt, package.json, pubspec.yaml, go.mod) for stack and decision data

**Without Axon:**
1. Read CLAUDE.md and any existing project documentation for documented conventions
2. Read package manifests to identify stack and key dependencies
3. Identify entry points — glob for urls.py, app/layout.tsx, main.dart, main.go, index.ts, etc.
4. Read entry point files to understand the top-level structure
5. Glob for structural patterns: `**/services.py`, `**/repositories.py`, `**/middleware.*`, `**/serializers.py`, `**/hooks/use*.ts`
6. Read 2-3 representative examples of each discovered pattern
7. Infer decisions from dependency choices and configuration files

**Incremental mode — both paths:**
1. Run `git log --since="[last-updated-date]" --stat --pretty=format:"%H %s"` to identify what changed
2. If Axon available, run `axon_detect_changes` on the range for structural impact
3. Classify changed files to determine which sections need updating:
   - Config/manifest changes → Stack, Decisions
   - New directories or apps → Architecture Overview, Conventions
   - New service/pattern files → Patterns
   - New middleware, validators, exception handlers → Constraints, Patterns
4. Re-analyze only the code relevant to affected sections
5. Skip sections whose underlying code did not change

### Step 4: Extract Architecture

For each of the six categories, extract concrete, specific findings — not generic descriptions. Every bullet should be grounded in what the code actually does.

| Category | What to capture | Example |
|----------|----------------|---------|
| **Stack** | Technology, version, directory | `Django 5.1 + DRF (server/)` |
| **Architecture Overview** | Layer map, boundaries, data flow | "Three-layer: views → services → models. All external API calls isolated in clients/" |
| **Decisions** | Technology/pattern choice + rationale | "JWT over sessions: stateless auth for mobile client support" |
| **Patterns** | Structural patterns to follow for new code | "API views use class-based ViewSets registered with DefaultRouter" |
| **Constraints** | Non-negotiable rules | "All list endpoints paginated (PageNumberPagination, default 20)" |
| **Conventions** | Naming, file org, project-specific norms | "Tests: apps/[domain]/tests/test_[module].py" |

Also identify **Key Entry Points** — the 3-5 files a developer would need to understand first.

**Multi-stack projects:** Detect multiple sub-projects (look for multiple package manifests at different directory levels, or sub-project directories in CLAUDE.md). Keep Decisions and Constraints flat (project-wide). Give Patterns and Conventions per-stack subsections:

```markdown
## Patterns
### Backend (server/)
- ...
### Frontend (web/)
- ...
```

### Step 5: Write or Update architecture.md

**First Run / Full Refresh:**
- Use the template structure from `templates/architecture.md`
- Fill every section with extracted findings
- Set the `Last updated` date to today
- Write to `.claude/architecture.md`
- On Full Refresh: preserve the entire `## Manual Notes` section and everything below it from the existing file

**Incremental:**
- Read the existing `.claude/architecture.md` in full
- Update only the sections identified in Step 3 as affected
- Do NOT rewrite sections whose underlying code hasn't changed
- NEVER modify the `## Manual Notes` section or anything below it
- Update the `Last updated` date

**Size discipline:** Target under 200 lines. This file loads into every session's context. If a section grows beyond 10 bullets, consolidate or move detail to the Manual Notes section. Prioritize the patterns and conventions Claude needs most frequently.

### Step 6: Wrap Up

After writing/updating the file:
1. Summarize what was found or changed
2. Note if anything looks unusual or worth the user's attention
3. Mention the drift detector: *"You can check recent changes against these conventions by loading `agents/drift-detector.md` as a subagent."*

## Quick Reference

| Mode | Trigger | Scope | Manual Notes |
|------|---------|-------|--------------|
| First Run | No architecture.md exists | Full analysis | N/A |
| Incremental | architecture.md exists (default) | Changed sections only | Preserved |
| Full Refresh | User passes `--full` | Full re-analysis | Preserved |

| Axon Available | Analysis Approach |
|----------------|-------------------|
| Yes | axon_query → axon_context → axon_cypher + manifest reads |
| No | Entry point reads → glob for patterns → representative file reads |

## Common Mistakes

- **Overwriting Manual Notes** — never modify content after the `## Manual Notes` heading
- **Rewriting unchanged sections** — in incremental mode, only touch sections affected by recent changes
- **Generic descriptions** — "uses a service layer" is useless. "Business logic in `apps/*/services.py`, views call service functions, never access ORM directly" is useful
- **Too long** — if the file exceeds 200 lines, it costs more context than it saves. Trim aggressively
- **Missing rationale in Decisions** — "uses JWT" isn't a decision. "JWT over sessions: needed stateless auth for mobile clients" is
