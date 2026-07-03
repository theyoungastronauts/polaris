# Verification Report: Phase 8 — Verification coverage gaps

## Summary
All four Phase 8 tasks are implemented correctly. The two new stack-specific verify skills (`verify-nextjs-mui.md`, `verify-nextjs-shadcn.md`) are short/checklist-style and genuinely check the always/never rules their bootstraps emphasize — I re-derived several rules from `nextjs-mui-bootstrap.md` and `nextjs-shadcn-bootstrap.md` independently and every one has matching coverage, including two "uncited" rules I picked to test for cherry-picking. The Tailwind-v4 §10 placement in the shared `verify-nextjs.md` (skip-for-MUI, shadcn points to it) is coherent and a reasonable reading of the plan. Profiles and the README table are wired correctly. `./install.sh validate` passes. **Verdict: PASS.**

## Results

| Check | Status | Notes |
|-------|--------|-------|
| Task 1 — two new verify skills | PASS | MUI + ShadCN checklists cover the plan's named items. |
| Task 2 — Tailwind v4 placement | PASS | §10 in verify-nextjs.md, scoped; skip-for-MUI + shadcn-points-to-it coherent. |
| Task 3 — verify-nextjs.md additions | PASS | Trailing-slash, lib/api.ts, dates-via-dayjs, /react pointer all present. |
| Task 4 — profile + README wiring | PASS | `cmd:` entries correct; README rows match table format. |
| Bootstrap coverage (item 2) | PASS | Re-derived rules from both bootstraps; all covered. |
| Cherry-pick check (item 4) | PASS | 2 uncited always/never rules also have coverage. |
| Scope | PASS | Only the Output-list files changed. |

## Task-by-task

### Task 1 — new verify skills (PASS)
- `verify-nextjs-mui.md`: §1 sx discipline (+ no-Tailwind/Emotion-only), §2 `AppRouterCacheProvider` `enableCssLayer` + `InitColorSchemeScript` + ThemeProvider/CssBaseline-in-layout, §3 Grid `size` prop. Matches the plan's "sx discipline, AppRouterCacheProvider/Emotion SSR, InitColorSchemeScript, Grid size."
- `verify-nextjs-shadcn.md`: §1 `components.json` (+ `cn()`), §2 `@/components/ui` imports + `cn()` merging, §3 next-themes. Matches the plan's "components.json, cn(), next-themes, ui/ import paths."
- Both are checklist-style with the same structure as existing verify-*.md files (Purpose / Verification Process / Output). Small, not essays.

### Task 2 — Tailwind v4 placement (PASS; coherent)
§10 "Styling — Tailwind v4" added to the shared `verify-nextjs.md`, header-scoped "Tailwind stacks only: shadcn / plain Next.js — skip for MUI." Covers all plan items: no `tailwind.config` / `@import "tailwindcss"` + `@theme`, OKLCH semantic tokens, CVA via `cn()`, `size-*` + no `forwardRef`, dark via `@custom-variant dark`.
- `verify-nextjs-mui.md` Purpose says "skip the Tailwind section of verify-nextjs.md" — correct.
- `verify-nextjs-shadcn.md` Purpose says "also run the Tailwind v4 section of verify-nextjs.md" — correct.
- Plain Next.js uses verify-nextjs.md directly (§10 included). No double-coverage, no gaps.
This is a reasonable reading of "add to the frontend verify files that pair with /tailwind" — it covers the nextjs family (plain + shadcn) through the shared file while keeping MUI from wrongly applying Tailwind checks. It avoids duplicating the checklist into shadcn's file. Not a stretch. (Astro note below.)

### Task 3 — verify-nextjs.md additions (PASS)
- §3: "API endpoints use trailing slashes (DRF convention)" and "API calls in a single `lib/api.ts` — generic `apiFetch<T>` + namespaced exports (`authApi`, `itemsApi`), not scattered fetch."
- §4: "Backend dates typed as `string` (ISO 8601), parsed with `dayjs` — not read as `Date` off the wire."
- §5 Performance: pointer to the `/react` skill "57 rules across 8 categories." (Lead confirmed the reference resolves and the wording is verbatim.)

### Task 4 — wiring (PASS)
- `profiles/nextjs-mui.txt`: `cmd:verify-nextjs-mui=skills/verification/verify-nextjs-mui.md`.
- `profiles/nextjs-shadcn.txt`: `cmd:verify-nextjs-shadcn=skills/verification/verify-nextjs-shadcn.md`.
- README On-Demand table: two new rows with the correct 3-column format (command | description | profile) and correct profile scoping (`nextjs-shadcn`, `nextjs-mui`). `./install.sh validate` passes.

## Independent coverage re-derivation (item 2) + cherry-pick probe (item 4)

Re-derived always/never rules straight from the bootstraps and matched each to a verify item:

**MUI bootstrap:**
- `<AppRouterCacheProvider options={{ enableCssLayer: true }}>` (:387) → verify-mui §2 (verbatim). ✓
- `<InitColorSchemeScript attribute="data-mui-color-scheme" />` (:386) → verify-mui §2 ("matching the theme's attribute"). ✓
- "ThemeProvider, CssBaseline, AppRouterCacheProvider already in layout.tsx; Providers only handles app-level context" (:803) → verify-mui §2 "not re-declared in nested providers." ✓
- "No postcss.config/globals.css — MUI via Emotion. No Tailwind" (:87) → verify-mui §1. ✓
- `<Grid size={{ xs: 12, sm: 6 }}>` (:1143, MUI v7) → verify-mui §3 (v6+ `size`, not `item` + xs/sm). ✓ Confirmed the bootstrap uses `size`, not the deprecated form.

**ShadCN bootstrap:**
- `components.json` with `"ui": "@/components/ui"` (:169) → verify-shadcn §1 (verbatim). ✓
- `cn()` = `twMerge(clsx(...))` in lib/utils.ts (:331) → verify-shadcn §1. ✓
- "Always import ShadCN components from `@/components/ui/<component>`" (:1240) → verify-shadcn §2. ✓
- `<ThemeProvider attribute="class" ... disableTransitionOnChange>` (:874) → verify-shadcn §3. ✓
- `@custom-variant dark (&:where(.dark, .dark *))` (:341) + `.dark {` (:378) → verify-shadcn §3 + verify-nextjs §10. ✓

**Cherry-pick probe** — two always/never rules I picked that the executor's spot-check would be less likely to cite, both covered:
- "The Makefile is the sole interface — never run `npm` directly on the host" (both bootstraps :7) → covered in verify-nextjs.md §9 ("No `npm run`/`npx` on host" + "Makefile wraps all commands"). ✓
- MUI theme colors (`color: 'primary.main'` :561, `'text.secondary'` :947) → verify-mui §1 "Colors and spacing come from the theme … not hardcoded hex/px." ✓

No cherry-picking evident — coverage is comprehensive across the emphasized rules, not selective.

## Issues

### FAIL (must fix)
- None.

### WARN (should review)
- None.

### Suggestions (optional)
- **Astro also pairs with `/tailwind`** (`profiles/astro.txt` has `cmd:tailwind=…`) and its `verify-astro.md` §5 Styling has **no** Tailwind-v4 coverage, so under a literal reading of Task 2 ("the frontend verify files that pair with /tailwind") astro is a residual gap. Leaving it out is defensible and I do not count it against this phase: (a) Assumption 2 explicitly deprioritizes Astro ("gets no currency work"); (b) Phase 8's Output scopes only the `nextjs-mui`/`nextjs-shadcn` profiles; (c) several §10 items are React-specific (`CVA`, `forwardRef`/React-19 ref, `size-*`) and don't transplant cleanly to Astro components. If the lead later wants astro Tailwind coverage, it needs an astro-flavored subset (config-less `@theme`/OKLCH), not a copy of §10.

## Verdict
**PASS** — all four tasks correct; the new verify skills check what their bootstraps emphasize (independently confirmed, no cherry-picking), the Tailwind-v4 placement is coherent, and wiring is correct. The only note is an optional, out-of-scope-by-design astro Tailwind gap consistent with Assumption 2.
