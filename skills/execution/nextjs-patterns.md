# Skill: Next.js Patterns

## Purpose
Guide Claude Code when implementing Next.js features. Projects use one of two modes — check the project's CLAUDE.md or ask.

## Project Structure
- Use App Router (`src/app/` directory) with `@/*` path alias
- Components organized by feature (`components/goals/`, `components/settings/`), not by type
- Shared UI components in `components/ui/` with barrel `index.ts` exports
- Custom hooks in `lib/hooks/` with barrel `index.ts` exports
- All API types in a single `types/api.ts` — split only if it exceeds ~800 lines
- All API functions in a single `lib/api.ts` organized into namespaced objects

## Components
- PascalCase filenames matching the component name, default exports
- Props interface defined above the component, suffixed with `Props`
- Use `import type { ... }` for type-only imports
- Always handle loading, empty, and error states on every page

## API Client
- Single `lib/api.ts` with generic `apiFetch<T>` base function
- Namespaced exports per domain: `authApi`, `itemsApi`, etc.
- `ApiError` class with `status`, `message`, `data` fields
- Trailing slashes on all endpoints (Django REST Framework convention)
- UUIDs as primary identifiers in URLs

## Styling
- DaisyUI semantic colors: `base-100`, `base-content`, `primary` — never hardcoded hex in components
- Tailwind v4 syntax (`@import "tailwindcss"`, DaisyUI as `@plugin`)
- Responsive-first — mobile breakpoints before desktop

## Types
- `interface` for object shapes, `type` for unions/aliases
- String literal unions for status fields (not enums)
- Separate `CreateRequest` / `UpdateRequest` types (update fields optional)
- Dates from backend are `string` (ISO 8601) — parse with `dayjs`

## Naming
- Components: PascalCase files + default exports
- Hooks: camelCase with `use` prefix, named exports
- API namespaces: camelCase with `Api` suffix (`itemsApi`)
- Constants: `UPPER_SNAKE_CASE`
- Directories: kebab-case for routes, camelCase for lib

---

## Frontend-Centric Mode
SPA-like architecture, decoupled from backend. Most components are interactive.

- Most components use `'use client'` — client-first approach
- Data fetching: `useEffect` + `useState` (no React Query/SWR)
- State: React Context for global (auth/user), `useState` for local — no Redux/Zustand
- Auth: JWT via localStorage (`lib/auth.ts`), `UserContext` + `useUser()` hook, `useRequireAuth()` guard, `router.replace` for redirects — no Next.js middleware
- Errors: try/catch with `ApiError` instanceof check + `react-hot-toast`, always `finally` for loading state
- Use `/nextjs-bootstrap` with frontend-centric mode to scaffold

## SSR-Centric Mode
Server-rendered, leveraging Next.js built-in features.

- Default to Server Components; `'use client'` only for interactivity, hooks, browser APIs
- Data fetching: Server Components fetch directly; client components use React Query/SWR
- State: React Query for server state, Context or Zustand for complex UI state
- Auth: Next.js middleware or server-side session checks
- Errors: `error.tsx` boundaries at route level, `loading.tsx` / Suspense for loading states
- Testing: React Testing Library, MSW for API mocking, Playwright for E2E
- Use `/nextjs-bootstrap` with SSR-centric mode to scaffold
