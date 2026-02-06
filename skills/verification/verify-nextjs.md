# Skill: Verify Next.js

## Purpose
Systematic verification checklist for Next.js/React code. Used by the reviewer agent after code execution.

## Verification Process

### 1. Tests
- [ ] Tests exist for new/changed components and logic
- [ ] Tests pass (`npm test` / `vitest`)
- [ ] Tests cover user interactions, not implementation details
- [ ] API mocking is realistic (matches actual response shapes)

### 2. Components
- [ ] Server vs Client Components used appropriately
- [ ] No unnecessary `"use client"` directives
- [ ] Props are typed — no `any` types
- [ ] Components are reasonably sized (extract if >150 lines)
- [ ] Key props on list items

### 3. Data Fetching
- [ ] No waterfalls — parallel fetches where possible
- [ ] Loading states handled (loading.tsx or Suspense)
- [ ] Error states handled (error.tsx or error boundaries)
- [ ] Caching strategy is intentional (not accidental)

### 4. Types
- [ ] API response types match the integration summary
- [ ] No `any` escape hatches without comments explaining why
- [ ] Shared types are in `types/` not duplicated across files
- [ ] `tsc --noEmit` passes cleanly

### 5. Performance
- [ ] Images use next/image
- [ ] No unnecessary re-renders (check effect dependencies)
- [ ] Large lists are virtualized if >100 items
- [ ] Bundle impact is reasonable (no giant libraries for small tasks)

### 6. Accessibility
- [ ] Interactive elements are keyboard accessible
- [ ] Form inputs have labels
- [ ] Images have alt text
- [ ] Semantic HTML used (not div soup)

### 7. Security
- [ ] No secrets or API keys in client code
- [ ] User input is sanitized before rendering
- [ ] API calls include appropriate auth headers
- [ ] Server actions validate input

### 8. Code Quality
- [ ] No commented-out code
- [ ] No console.logs left in
- [ ] ESLint passes
- [ ] Consistent naming conventions

## Output
Produce a `verification-report.md` (same format as verify-django).
