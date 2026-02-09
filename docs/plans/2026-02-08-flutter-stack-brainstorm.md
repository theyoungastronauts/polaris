# Brainstorm: Flutter Stack Profile for Polaris

> Date: 2026-02-08
> Context: Bringing proven Flutter patterns from the Houston project into Polaris as a first-class stack profile paired with Django backends.

---

## Background

Houston is a blueprint-driven, full-stack code generation framework for Flutter apps. It uses Mason bricks and YAML blueprints to scaffold features across Flutter + three backend options (Django, Supabase, ServePod). The architecture is strong — clean architecture, Riverpod state management, multi-backend datasource abstraction, Freezed models, GoRouter — and has shipped multiple production projects.

With Polaris and Claude Code, the generation engine shifts from templates to AI. The blueprint YAML format and Mason bricks become redundant when Claude can read patterns + integration summaries and generate features directly — with more flexibility and context-awareness than templates ever could.

This brainstorm defines how to bring Houston's best patterns into Polaris as a Flutter stack profile.

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Scope** | Flutter stack profile (patterns + bootstrap) | Highest value. No need to port Mason/blueprints — Claude replaces the generation engine. |
| **Backend pairing** | Django only (for now) | Polaris already has strong Django support. Simplifies Flutter patterns. Other backends can be added later. |
| **Library stack** | Riverpod + Freezed + GoRouter + Dio | Proven stack from Houston. Modernized with codegen and AsyncNotifier. fpdart dropped. |
| **Architecture** | Clean architecture with service interface abstraction | Enables future backend swapping without refactoring providers/screens/widgets. |
| **Feature structure** | Flattened: models/services/providers/screens/widgets | Less nesting than Houston. Architecture boundaries maintained by convention + service interface. |
| **Bootstrap approach** | Interactive (Claude builds step by step) | Consistent with Django bootstrap. Claude asks for config values and creates each file. |
| **Bootstrap scope** | App shell + auth feature | Auth is genuinely hard to regenerate. Everything else Claude can generate from patterns + integration summaries. |
| **Integration** | Existing cross-repo workflow (as-is) | Integration summaries are backend-agnostic. Flutter reads the same format Next.js does. |

---

## Architecture

### Feature Structure

```
lib/
├── main.dart
├── config/
│   ├── env.dart                        # Compile-time env constants
│   └── constants.dart                  # App-wide constants
├── core/
│   ├── api/                            # Dio client, interceptors, auth headers
│   ├── error/                          # Sealed Failure class hierarchy
│   ├── router/                         # GoRouter config, auth redirect guard
│   ├── theme/                          # ThemeData, color extensions
│   ├── providers/                      # App-level providers (auth state, session)
│   ├── utils/                          # Validation, formatting, helpers
│   └── widgets/                        # Shared widgets (BaseScreen, dialogs, buttons)
├── features/
│   └── {feature}/
│       ├── models/
│       │   └── {feature}.dart          # Freezed model + JSON serialization
│       ├── services/
│       │   ├── {feature}_service.dart              # Abstract interface
│       │   └── {feature}_service_django.dart        # Django implementation
│       ├── providers/
│       │   ├── {feature}_service_provider.dart      # Binds interface → impl
│       │   └── {feature}_providers.dart             # List, detail, form providers
│       ├── screens/
│       │   ├── {feature}_list_screen.dart
│       │   ├── {feature}_detail_screen.dart
│       │   └── {feature}_edit_screen.dart
│       └── widgets/
│           └── {feature}_list_tile.dart
```

### Backend Swapping (Future-Proofed)

The service interface is the abstraction boundary:

```dart
// Abstract — providers depend on this
abstract class BookService {
  Future<List<Book>> list({int page, int limit});
  Future<Book> retrieve(int id);
  Future<Book> create(Book book);
  Future<Book> update(Book book);
  Future<void> delete(int id);
}

// Concrete — only this changes per backend
class BookServiceDjango implements BookService {
  final DioClient client;
  // ... Django REST API calls
}
```

Swapping to Supabase later:
1. Add `book_service_supabase.dart`
2. Change one provider binding in `book_service_provider.dart`
3. Nothing else changes

### Key Patterns (Modernized from Houston)

**State management:** Riverpod with `@riverpod` codegen everywhere. `AsyncNotifier` for stateful logic (forms, lists). `AsyncValue<T>` replaces manual loading/error/data state classes.

**Models:** Freezed with `json_serializable`. Models mirror API response shapes. `fromJson`/`toJson` generated.

**Error handling:** Sealed `Failure` class hierarchy (`ServerFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`). Services throw typed failures. Providers catch and surface via `AsyncValue.error`.

**API client:** Singleton Dio instance with interceptors (auth header injection, token refresh on 401, request/response logging). Timeout configuration. No raw `print()`.

**Navigation:** GoRouter with typed routes. Auth redirect guard checks session state. Deep linking support.

**Forms:** `AsyncNotifier`-based form providers. Validation via utility functions. Submit → loading state → success/error.

**Lists:** Infinite scroll and paginated variants via Riverpod providers. Cursor-based or page-based depending on API.

---

## What We're Building

| Deliverable | Description | Status |
|-------------|-------------|--------|
| `skills/execution/flutter-patterns.md` | Full architecture conventions with inline code examples for every layer. The primary document Claude reads when generating Flutter features. | New |
| `skills/execution/flutter-bootstrap.md` | Interactive bootstrap skill. Scaffolds app shell + auth feature. Asks for config values (API URL, app name, bundle ID, etc.). | New |
| `skills/verification/verify-flutter.md` | Verification checklist aligned with new patterns. | Update existing |
| `profiles/flutter.txt` | Profile config pointing to all Flutter skills. | Update existing |

### flutter-patterns.md — What It Covers

1. **Project structure** — directory layout, naming conventions, file organization
2. **Models** — Freezed conventions, JSON serialization, model relationships
3. **Services** — Abstract interface pattern, Django implementation, error handling
4. **Providers** — `@riverpod` codegen, `AsyncNotifier` for forms/lists, service binding
5. **Screens** — Responsive layout with `BaseScreen`, consuming providers, navigation
6. **Widgets** — Extraction rules, const constructors, composition patterns
7. **API client** — Dio setup, interceptors, token refresh flow
8. **Auth** — JWT session management, secure storage, auth state provider, route guards
9. **Error handling** — Sealed failure types, provider error surfacing, user-facing messages
10. **Forms** — Validation, submission, loading states, image upload
11. **Lists** — Infinite scroll, paginated, filtering, ordering
12. **Testing** — Unit tests for services/providers, widget tests for screens, mocking patterns

### flutter-bootstrap.md — What It Scaffolds

Interactive build that creates:

**Core shell:**
- `main.dart` with `ProviderScope`, `MaterialApp.router`
- `config/env.dart` with compile-time constants (API URL, app name)
- `config/constants.dart` with app-wide settings
- `core/api/` — Dio client with JWT interceptor, token refresh, timeout
- `core/error/` — Sealed `Failure` hierarchy
- `core/router/` — GoRouter with auth guard
- `core/theme/` — Material 3 theme setup
- `core/providers/` — Session provider, auth state
- `core/widgets/` — BaseScreen, common dialogs
- `core/utils/` — Validation utilities

**Auth feature (reference implementation):**
- `features/auth/models/` — `User`, `SessionToken` (Freezed)
- `features/auth/services/` — `AuthService` interface + `AuthServiceDjango`
- `features/auth/providers/` — Auth notifier, session persistence
- `features/auth/screens/` — Login, register screens
- `features/auth/widgets/` — Login form, register form

**Project config:**
- `pubspec.yaml` with pinned dependencies
- `analysis_options.yaml` with strict linting
- `build.yaml` for Freezed/Riverpod codegen
- `.gitignore`

---

## What Doesn't Come Over from Houston

| Houston Component | Disposition | Reason |
|-------------------|-------------|--------|
| Mason bricks & CLI | Dropped | Claude Code replaces the generation engine |
| Blueprint YAML files | Dropped | Plan docs + integration summaries carry the intent |
| Multi-backend datasource abstraction | Simplified | Interface + one impl. Expandable later without refactor. |
| `houston_client` package | Dropped | ServePod-specific |
| fpdart `Either` pattern | Dropped | `AsyncValue` handles loading/error/data natively |
| Manual state classes | Dropped | `AsyncNotifier` replaces `ProfileFormState`, etc. |
| `BaseComponent` / triple body methods | Simplified | Responsive handled more simply |
| `AppButton` mega-widget | Dropped | Use theme-level button styling |
| data/domain/presentation nesting | Flattened | Same boundaries, less directory depth |

## What Carries Forward

| Houston Pattern | How It Appears in Polaris |
|-----------------|--------------------------|
| Clean architecture layers | Service interface abstraction in every feature |
| Feature-based organization | `features/{name}/` with consistent sub-structure |
| Riverpod state management | Modernized with `@riverpod` codegen + `AsyncNotifier` |
| Freezed immutable models | Same, with `json_serializable` |
| GoRouter navigation | Same, with typed routes and auth guards |
| Dio HTTP client | Same, with singleton instance + interceptors |
| JWT auth flow | Token refresh, session persistence, auth state provider |
| Form validation patterns | Carried forward, simplified with `AsyncNotifier` |
| Infinite scroll / paginated lists | Provider-based patterns, documented in skills |
| Image upload pipeline | Documented in patterns skill |
| Responsive design | `BaseScreen` pattern, simplified |

---

## Workflow

For a typical full-stack project with Django + Flutter:

1. **Brainstorm** → design doc
2. **Plan** → `plan.md` with phased backend + frontend work
3. **Scaffold** → `/scaffold` creates `api/` (Django) + `mobile/` (Flutter), installs stack profiles
4. **Backend phases** → Execute Django phases. Each API phase generates integration summary.
5. **Pull context** → `context-pull.sh ../api` from Flutter directory
6. **Frontend phases** → Claude reads flutter-patterns + integration summaries. Generates features: models matching API shapes, services calling the right endpoints, providers, screens, widgets.
7. **Verify** → Fresh session verifies each phase against the plan.

The integration summary is the contract between backend and frontend. Claude on the Flutter side reads it and knows exactly what endpoints exist, what they accept, and what they return.

---

## Open Questions for Implementation

1. **Dependencies pinning** — Should `flutter-bootstrap.md` specify exact dependency versions, or use latest stable with `^` ranges? Exact versions prevent breakage but need periodic updates.

2. **Testing patterns** — How much test scaffolding should bootstrap create? Empty test structure? A reference test for the auth feature?

3. **Platform targets** — Should bootstrap ask which platforms to target (iOS, Android, Web, macOS, etc.) and configure accordingly?

4. **CI/CD** — Should a GitHub Actions workflow be part of the bootstrap (flutter analyze, test, build)?

---

## Next Step

> Design is saved. When you're ready to turn this into a phased implementation plan, start a new session with the planner agent — it will read this design doc and break it into scoped, executable phases.
