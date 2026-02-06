# Skill: Django Patterns

## Purpose
Guide Claude Code when implementing Django/DRF features. Follow these conventions unless the project's CLAUDE.md overrides them.

## Project Structure
- Project settings module is always named `project/` (not the service name)
- Apps live in their own top-level directories
- Each app has: `admin.py`, `apps.py`, `models.py`, `serializers.py`, `services.py`, `tasks.py`, `urls.py`, `views.py`, `tests/`
- Tests use a `tests/` directory with files per concern: `test_models.py`, `test_views.py`, `test_services.py`

## Models
- All models inherit from `AbstractModel` (provides `uuid`, `metadata`, `created_at`, `updated_at`, `silent_save()`)
- Use the inherited `uuid` field for public-facing IDs, keep integer PKs internal
- Add `__str__` methods to every model
- Use `Meta.ordering` to define default ordering
- Keep models thin — business logic goes in `services.py`

## Service Layer
- Each app has a `services.py` — all business logic lives here, not in views or models
- Services are classes with external dependencies injected via `__init__`
- Views call services; services call models and external APIs
- This keeps views thin and business logic testable without HTTP

## Serializers (DRF)
- Separate read vs write serializers when shapes differ
- Use `SerializerMethodField` sparingly — prefer annotations at the queryset level
- Validate at the serializer level, not the view level
- Always define `fields` explicitly (never use `__all__`)

## Views
- Prefer ViewSets for CRUD, APIView for custom actions
- Use `select_related` / `prefetch_related` on querysets to avoid N+1
- Views should only: parse request, call service, return serialized response
- Use `permission_classes` explicitly on every view

## URLs
- Each app exports `urlpatterns` from `urls.py`
- `project/urls.py` aggregates with namespacing: `path("api/v1/{app}/", include(({app}_urlpatterns, "{app}")))`
- Use DRF routers for ViewSets

## Celery Tasks
- Use `@shared_task(bind=True, max_retries=3, default_retry_delay=60)`
- Tasks call services — no business logic in the task itself
- Keep tasks in each app's `tasks.py`

## Migrations
- Review auto-generated migrations before committing
- Add `RunPython` data migrations when needed alongside schema changes
- Never edit a migration that's been pushed to main

## Testing
- Use `pytest-django` with `@pytest.mark.django_db`
- Use factory_boy for test data (not fixtures)
- Test API endpoints via `APIClient` — test the contract, not internals
- Test services independently with unit tests (no HTTP layer)
- Aim for: service logic tests, serializer validation tests, endpoint integration tests

## Development Environment
- All commands run via `make` (Docker Compose under the hood) — never run `python manage.py` directly
- Use `/django-bootstrap` when setting up a new project from scratch

## Integration Summaries
After completing a backend feature, generate an integration summary:
- List all new/modified endpoints with method, path, auth requirements
- Include request/response shapes as JSON examples
- Note any pagination, filtering, or ordering parameters
- Document error response shapes
- Save to `docs/integration/[feature-name].md`
