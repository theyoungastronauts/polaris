# Integration Summary: [Feature Name]

> Generated: [date]
> Backend Branch: [branch]
> Status: [draft/final]

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
- Style: [cursor/offset/page-number]
- Default page size: [N]
- Max page size: [N]
- Response shape: `{"count": N, "next": "url", "previous": "url", "results": [...]}`

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
