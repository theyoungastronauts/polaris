# Verification Report: Phase 6 — Canonical cross-stack API contract

## Summary
All four Phase 6 tasks are implemented across the four Output files (`django-patterns.md`, `django-bootstrap.md`, `nextjs-fullstack-bootstrap.md`, `templates/integration-summary.md`). One documented contract now exists; Django ships exactly it (custom paginator, auth URLs, uuid-only serializers); the Next.js consumers match it verbatim (endpoints **and** payloads); the fullstack app emits the contract pagination shape. The lead's JWT rotation fix is **correct and necessary**. `./install.sh validate` passes. One WARN: `SIMPLE_JWT["USER_ID_FIELD"] = "id"` embeds the integer PK in the JWT `user_id` claim, the one place the integer id becomes client-visible — a technicality against the contract's headline "clients only ever see uuid." **Verdict: PASS WITH WARNINGS.**

## Results

| Check | Status | Notes |
|-------|--------|-------|
| Task 1 — contract in django-patterns | PASS | Precise and complete (below). |
| Task 2 — Django ships the contract | PASS | Paginator + `DEFAULT_PAGINATION_CLASS` in both REST blocks; auth URLs shipped. |
| Task 3 — Next.js consumers match | PASS | Endpoints + payloads verbatim; no edits needed (re-verified). |
| Task 4 — integration-summary cross-ref | PASS | Baseline note + pagination shape updated. |
| Lead's JWT rotation fix | PASS | Rotation OFF → `TokenRefreshView` returns `{access}` only; matches contract + frontend. |
| Fullstack pagination (item 7) | PASS | `{page, count, num_pages, results}` + `page`/`page_size`. |
| Email uniqueness + login (item 6) | PASS | Coherent, no leftover username-login path, correctly scoped. |
| verify-django:32 pagination check | PASS | Now satisfiable by the shipped paginator. |
| Scope | PASS | 4 files; email field + JWT fix both justified. |
| Identifier exposure (item 5) | WARN | Serializers clean; JWT `user_id` claim exposes integer id (below). |

## Task 2 — contract section (django-patterns.md) is source-of-truth quality
Exact prefix (`/api/v1`, trailing slash), identifier rule (clients see `uuid`; internal integer PK; detail routes `path("<uuid:uuid>/", ...)`), an auth-endpoint table with exact request/response shapes (`login {email,password}→{access,refresh}`, `refresh {refresh}→{access}`, `me→user object`, `register {username,email,password,first_name,last_name}→{user,tokens:{access,refresh}}`), the user-object shape (`{uuid,username,email,first_name,last_name}` — no id), a resource endpoint table keyed by uuid, an explicit note that the self-contained Next.js app applies the same prefix/uuid/pagination (minus trailing slash), and the pagination shape `{page,count,num_pages,results}` with `page`/`page_size` params (explicitly flagged as custom, not DRF's default). Precise and complete.

## Task 3 — Next.js consumers match verbatim (re-verified, not trusted)
Grepped endpoint literals across all three frontend bootstraps (`nextjs-bootstrap.md`, `nextjs-mui-bootstrap.md`, `nextjs-shadcn-bootstrap.md`): each uses base `/api/v1` + `/auth/login/`, `/auth/register/`, `/auth/refresh/`, `/auth/me/` — trailing slashes present, all appearing verbatim in the contract. No stray endpoint literal bypasses the `/api/v1` prefix. Spot-checked `nextjs-bootstrap.md` auth client **payloads/responses** too: `login` sends `{email,password}` and reads `{access,refresh}`; `register` reads `response.tokens.{access,refresh}`; `refresh` sends `{refresh}` and reads `.access`; `me` returns the user object. All match the contract exactly, confirming the executor's "no edits needed" claim.

## Lead's JWT rotation fix — correct AND necessary
`ROTATE_REFRESH_TOKENS: False` (was `True`), `BLACKLIST_AFTER_ROTATION` removed.
- **Correct:** stock SimpleJWT `TokenRefreshView` (via `TokenRefreshSerializer`) returns **`{access}` only** when `ROTATE_REFRESH_TOKENS=False`; it adds a new `refresh` to the body only when rotation is on. So the shipped response now genuinely matches the contract's documented `{access}`.
- **Sufficient:** removing `BLACKLIST_AFTER_ROTATION` is safe — it is a no-op without rotation.
- **Necessary (confirmed against the consumer):** the frontend `refresh()` reuses its **original** refresh token (`setTokens(response.access, refreshToken)`) and reads only `.access`. With rotation ON + blacklist, the first refresh would rotate and blacklist the old token, so the frontend's second refresh (still sending the original) would 401. Rotation OFF is exactly what this consumer requires. The prior config would have silently diverged from both the contract and the client.
- Note: `rest_framework_simplejwt.token_blacklist` remains in INSTALLED_APPS though nothing now rotates/blacklists (no logout endpoint is shipped). Vestigial but harmless — it could back a future logout-blacklist. Optional cleanup, not a defect.

## Item 5 — identifier exposure sweep
Every serializer in `django-bootstrap.md` is clean: `UserSerializer` enumerates `["uuid","username","email","first_name","last_name"]` with `read_only_fields=["uuid"]` (no `id`); `RegisterSerializer` is input-only `["username","email","password","first_name","last_name"]`; `LoginSerializer` is a plain `Serializer`. No `fields="__all__"`, no explicit `id`, and there is no example resource serializer that could leak `id`. The `filter(pk=self.pk).update(...)` at :285 is internal ORM, not a response. Views/URLs are uuid-keyed. So the contract's scoped rule — "**URLs and payloads** expose the public uuid field only" — is fully satisfied.

**The one exposure (WARN):** `SIMPLE_JWT["USER_ID_FIELD"] = "id"` (:771) puts the integer PK into every access/refresh token's `user_id` claim. A JWT is base64, not encrypted, so a client decoding its own token can read the integer id. This is at odds with the contract's broader headline "clients only ever see `uuid` … never the integer id," even though the narrowly-scoped "URLs and payloads" wording is met. Low risk (it is the client's own id, the token is an opaque credential, and no API surface accepts/returns integer ids), but it is the single place the integer id reaches the client.

## Item 6 — email uniqueness + email login
`email = models.EmailField(unique=True)` overrides `AbstractUser.email`; `LoginSerializer` resolves the account by `email` then `check_password` + `is_active`. No leftover username-based login path exists in the API (the auth URLs are login[email]/refresh/me/register); `AbstractUser.USERNAME_FIELD="username"` only affects admin/`createsuperuser`, not the API. `AbstractUser.REQUIRED_FIELDS=["email"]` keeps superuser creation supplying an email, so the unique constraint can't collide on blanks. Uniqueness is **required** for `{email,password}` login to resolve a single user — a necessary supporting change, not scope creep. Coherent and correctly scoped.

## Item 7 — fullstack pagination
`listPosts(userId, {page, pageSize})` now returns `{results, count}` (limit/offset + a `count()` query, both user-scoped) and the `GET` handler parses `page`/`page_size` (clamped: page≥1, size 1–100 default 20) and responds `{page, count, num_pages: max(1, ceil(count/pageSize)), results}`. Matches the contract shape and params. This also closes the pagination item deferred from Phase 5.

## Task 4 / pagination wiring
`project/pagination.py` ships `StandardResultsSetPagination(PageNumberPagination)` with `page_size=20`, `page_size_query_param="page_size"`, `max_page_size=100`, and `get_paginated_response` emitting `{page, count, num_pages, results}` — matches the contract exactly (the `page` param is PageNumberPagination's inherited default). Wired as `DEFAULT_PAGINATION_CLASS` in **both** REST_FRAMEWORK blocks (:722 and :750). `verify-django.md:32`'s "Pagination is configured for list endpoints" is now satisfiable out of the box by the shipped bootstrap.

## Issues

### FAIL (must fix)
- None.

### WARN (should review)
- `skills/execution/django-bootstrap.md:771` — `SIMPLE_JWT["USER_ID_FIELD"] = "id"` embeds the integer PK as the JWT `user_id` claim, the one place the integer id is client-visible, mildly at odds with the contract's "clients only ever see uuid." **Two ways to close it:** set `USER_ID_FIELD = "uuid"` (valid — `uuid` is unique; SimpleJWT will carry/lookup by it) to fully honor the headline, **or** narrow the contract prose to "URLs and response payloads expose uuid only" to match the shipped reality and accept the token claim as an internal auth detail. Low severity; does not affect resource addressing (all uuid-keyed).

### Suggestions (optional)
- `token_blacklist` stays installed though rotation is off and no endpoint blacklists — remove it or wire a logout-blacklist endpoint if desired. Harmless as-is.

## Verdict
**PASS WITH WARNINGS** — one documented contract, shipped by Django and consumed verbatim by Next.js, with a correct-and-necessary JWT rotation fix and gap-free pagination. The single WARN is the integer PK riding in the JWT `user_id` claim (a wording-vs-code decision for the lead, not a security hole).
