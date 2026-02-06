# Using Git Worktrees for Phased Development

> Inspired by [obra/superpowers](https://github.com/obra/superpowers), adapted for phase-based workflow.

## Overview

Create isolated workspaces per phase of a plan using git worktrees. Each phase gets its own branch, its own directory, and can be developed and reviewed independently.

## When to Use

- After a plan has been broken into phases (see `phase-breakdown` skill)
- When starting execution of any phase
- When you need parallel work on multiple phases

## Setup Flow

### 1. Verify Clean State

Before creating any worktrees, verify the source branch is clean:

```bash
# Ensure we're on the base branch (usually main or develop)
git checkout main
git pull origin main

# Verify clean working tree
git status --porcelain
# If not clean: stash or commit before proceeding
```

### 2. Choose Worktree Location

Worktrees are created as sibling directories to the repo within the project root. Typical project structure:

```
~/prj/my-project/
  backend/                 # git repo
  frontend/                # git repo
  resources/               # docs, designs, etc.
  backend-phase-1/         # worktree
  backend-phase-2/         # worktree
  frontend-phase-1/        # worktree
  user-auth.code-workspace # VS Code workspace for this feature
```

Naming convention: `{repo-name}-phase-{N}` or `{repo-name}-{short-description}` for clarity.

### 3. Create Worktree

```bash
# From the main repo root
REPO_NAME=$(basename $(pwd))
FEATURE="feature-name"
PHASE=1

# Create worktree with new branch
git worktree add "../${REPO_NAME}-phase-${PHASE}" -b "feature/${FEATURE}-phase-${PHASE}"
```

For a full plan with multiple phases:

```bash
# Create all phase worktrees at once
REPO_NAME=$(basename $(pwd))
FEATURE="user-auth"

for PHASE in 1 2 3; do
  git worktree add "../${REPO_NAME}-phase-${PHASE}" -b "feature/${FEATURE}-phase-${PHASE}"
  echo "✓ Created phase ${PHASE}: ../${REPO_NAME}-phase-${PHASE}"
done
```

### 4. Install Dependencies

After creating a worktree, detect the project type and install dependencies:

```bash
cd "../${REPO_NAME}-phase-${PHASE}"

# Python
if [ -f "pyproject.toml" ]; then
  poetry install 2>/dev/null || pip install -e ".[dev]" 2>/dev/null
elif [ -f "requirements.txt" ]; then
  pip install -r requirements.txt
fi

# Node.js
if [ -f "package-lock.json" ]; then
  npm ci
elif [ -f "yarn.lock" ]; then
  yarn install --frozen-lockfile
elif [ -f "pnpm-lock.yaml" ]; then
  pnpm install --frozen-lockfile
elif [ -f "package.json" ]; then
  npm install
fi

# Flutter/Dart
if [ -f "pubspec.yaml" ]; then
  flutter pub get
fi
```

### 5. Verify Clean Baseline

Run the test suite to confirm everything passes before making changes. This is critical — if tests fail before you start, you know it's not your fault.

```bash
# Python/Django
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  pytest --tb=short -q
fi

# Node.js/Next.js
if [ -f "package.json" ]; then
  npm test -- --watchAll=false 2>/dev/null || npx jest --passWithNoTests 2>/dev/null
fi

# Flutter
if [ -f "pubspec.yaml" ]; then
  flutter test
fi
```

**If tests fail:** Report the failures. Ask whether to proceed anyway or investigate first. Do not silently continue with a broken baseline — that makes verification meaningless later.

**If tests pass:** Report readiness:

```
✓ Worktree ready: ../my-app-phase-1
  Branch: feature/user-auth-phase-1
  Base: main (abc1234)
  Tests: 47 passing, 0 failures
  Ready to execute Phase 1
```

### 6. Install Skills (if using Polaris)

```bash
# From the worktree directory
~/prj/polaris/install.sh project --profile django-api
```

### 7. Generate VS Code Workspace

After creating all worktrees, generate a `.code-workspace` file in the project root so all phases are accessible from a single VS Code window.

```bash
# From the project root (parent of repos)
PROJECT_DIR=$(pwd)
FEATURE="user-auth"

cat > "${PROJECT_DIR}/${FEATURE}.code-workspace" << EOF
{
  "folders": [
    { "path": "backend", "name": "backend (main)" },
    { "path": "backend-phase-1", "name": "Backend Phase 1" },
    { "path": "backend-phase-2", "name": "Backend Phase 2" },
    { "path": "frontend", "name": "frontend (main)" },
    { "path": "frontend-phase-1", "name": "Frontend Phase 1" },
    { "path": "resources", "name": "resources" }
  ],
  "settings": {}
}
EOF
```

Only include folders that exist. Adjust the `folders` array to match the repos and phases for this feature. For single-repo projects, include just the main repo + its worktrees.

Open with:

```bash
code "${PROJECT_DIR}/${FEATURE}.code-workspace"
```

The sidebar shows each worktree as a labeled root with separate SCM panels per worktree.

## Working in Worktrees

### Switching Between Phases

Each worktree is a regular directory. Switch between them like any other project:

```bash
cd ../my-app-phase-1   # work on phase 1
cd ../my-app-phase-2   # switch to phase 2
cd ../my-app            # back to main repo
```

### Committing

Commits in a worktree happen on that worktree's branch. Normal git workflow applies:

```bash
# In phase 1 worktree
git add .
git commit -m "feat(auth): add user model and serializers"
```

### Keeping Phases Up to Date

If phase 2 depends on phase 1 being merged, rebase after phase 1 merges:

```bash
# In phase 2 worktree, after phase 1 is merged to main
git fetch origin
git rebase origin/main
```

If phases are independent, no rebasing needed until merge time.

### Pushing and Creating PRs

```bash
git push origin feature/user-auth-phase-1
# Create PR via GitHub CLI or web UI
gh pr create --title "feat(auth): Phase 1 - User model and API" \
  --body "Part of user-auth plan. See plan.md for full context."
```

## Cleanup

After a phase is merged and the PR is closed:

```bash
# From the main repo
git worktree remove ../my-app-phase-1
git branch -d feature/user-auth-phase-1  # delete local branch
```

Clean up all worktrees for a completed feature:

```bash
REPO_NAME=$(basename $(pwd))
for PHASE in 1 2 3; do
  WORKTREE="../${REPO_NAME}-phase-${PHASE}"
  if [ -d "$WORKTREE" ]; then
    git worktree remove "$WORKTREE"
    echo "✓ Removed $WORKTREE"
  fi
done

# Prune any stale worktree references
git worktree prune
```

Remove the VS Code workspace file when the feature is fully merged:

```bash
rm -f "../feature-name.code-workspace"
```

## Listing Active Worktrees

```bash
git worktree list
# /home/tyler/prj/my-app              abc1234 [main]
# /home/tyler/prj/my-app-phase-1      def5678 [feature/user-auth-phase-1]
# /home/tyler/prj/my-app-phase-2      ghi9012 [feature/user-auth-phase-2]
```

## Cross-Repo Worktrees

For fullstack features with backend + frontend repos under the same project root:

```bash
# From the project root (~/prj/my-project/)
cd backend
git worktree add ../backend-phase-1 -b feature/user-auth-phase-1

cd ../frontend
git worktree add ../frontend-phase-2 -b feature/user-auth-phase-2
```

Then generate a single workspace file covering both repos and all worktrees (see step 7 above).

Phase ordering for cross-repo work:
1. Backend phases first (API + integration summary)
2. Frontend phases consume the integration summary
3. Never have a single phase spanning both repos

## Common Issues

**"fatal: is already checked out"** — You're trying to create a worktree for a branch that's already checked out somewhere. Use a new branch name.

**Shared node_modules/venv** — Each worktree has its own working directory but shares `.git`. Dependency directories (`node_modules`, `.venv`, `build/`) are per-worktree and need separate installs.

**IDE confusion** — Use the generated `.code-workspace` file to open all worktrees in a single VS Code window with proper isolation. Avoid opening worktrees individually within the same window without a workspace file.
