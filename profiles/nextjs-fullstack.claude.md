#### Backend: Next.js (Full Stack)

- **Location**: `{directory}/`
- **Stack**: TypeScript, Next.js (App Router), Drizzle ORM, PostgreSQL, Redis, BullMQ, Auth.js v5
- **Key patterns**: the `nextjs-fullstack-patterns` skill (auto-loads; installed at `.claude/skills/nextjs-fullstack-patterns/SKILL.md`)
- **Testing**: Vitest with service unit tests and route handler integration tests
- **Integration**: After API changes, generate integration summaries in `docs/integration/`
- **Note**: When paired with a frontend profile, both share the same directory. Ignore the "API Client" and "Frontend-Centric Mode" sections of the `nextjs-patterns` skill — use server actions and the service layer instead.
