# Integration Summary: [Feature Name]

> Generated: [date]
> Backend Branch: [branch]
> Status: [draft/final]

> **Baseline:** this API follows the **Canonical API Contract** in the `django-patterns` skill — `/api/v1` prefix, `uuid` public identifiers, the shared auth endpoints (`/api/v1/auth/login|refresh|me|register/`), and the `{page, count, num_pages, results}` pagination shape. Document only what this feature *adds or changes* on top of that baseline; don't re-specify the contract.

## Overview
Brief description of what this feature does from the API perspective.

## Endpoints

### `[METHOD]` `/api/v1/[path]/`
- **Auth**: Required / Optional / None
- **Permissions**: [list or "any authenticated user"]

**Request:**
```json
{
}
```

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| | | | |

**Response (200):**
```json
{
}
```

**Response (201):** *(if applicable)*
```json
{
}
```

**Error Responses:**
| Status | Condition | Body |
|--------|-----------|------|
| 400 | Validation error | `{"field": ["error"]}` |
| 401 | Not authenticated | `{"detail": "..."}` |
| 403 | No permission | `{"detail": "..."}` |
| 404 | Not found | `{"detail": "..."}` |

---
*(Repeat for each endpoint)*

## Pagination
Follows the **Canonical API Contract** (see the `django-patterns` skill) — inherit it rather than restating it; only note per-endpoint deviations here.
- Response shape: `{"page": N, "count": N, "num_pages": N, "results": [...]}`
- Query params: `page`, `page_size`
- Default page size: 20 (max 100) unless this endpoint overrides it

## WebSocket Events *(if applicable)*
| Event | Direction | Payload |
|-------|-----------|---------|
| | | |

## Models Changed
| Model | Change | Notes |
|-------|--------|-------|
| | | |

## Notes
- Any special behavior, caching, rate limiting, etc.
- Anything the frontend developer should know that isn't obvious from the API shape
