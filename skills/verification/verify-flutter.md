# Skill: Verify Flutter

## Purpose
Systematic verification checklist for Flutter/Dart code. Used by the reviewer agent after code execution.

## Verification Process

### 1. Tests
- [ ] Tests exist for new/changed code
- [ ] `flutter test` passes
- [ ] Business logic has unit tests
- [ ] Key widgets have widget tests
- [ ] Mocks are realistic (use mocktail)

### 2. Models
- [ ] freezed/json_serializable code is generated and up to date (`build_runner`)
- [ ] Model shapes match API response (compare to integration summary)
- [ ] Null safety is handled correctly — no unnecessary `!` operators
- [ ] fromJson/toJson round-trips correctly

### 3. State Management
- [ ] State is immutable where possible
- [ ] No business logic in widgets
- [ ] Loading/error/success states all handled
- [ ] State disposal/cleanup is correct (no memory leaks)
- [ ] Providers/Blocs are scoped appropriately

### 4. Widgets
- [ ] Widget tree depth is reasonable (extract at 3-4 levels)
- [ ] `const` constructors used where possible
- [ ] No unnecessary rebuilds (check what triggers rebuilds)
- [ ] Responsive layout handles different screen sizes
- [ ] Scrollable content uses appropriate scroll widgets

### 5. Navigation
- [ ] Routes are defined and type-safe
- [ ] Back navigation works correctly
- [ ] Deep link handling tested
- [ ] No orphan routes

### 6. API Integration
- [ ] Error handling covers network failures, timeouts, unexpected responses
- [ ] Auth token refresh is handled
- [ ] Loading indicators shown during API calls
- [ ] Retry logic where appropriate

### 7. Platform Considerations
- [ ] No platform-specific code without appropriate checks
- [ ] Permissions requested before use (camera, location, etc.)
- [ ] Works on both iOS and Android (or target platforms)

### 8. Code Quality
- [ ] `dart analyze` passes with no issues
- [ ] No commented-out code
- [ ] No debug prints
- [ ] Imports are organized
- [ ] Consistent naming (camelCase for variables, PascalCase for classes)

## Output
Produce a `verification-report.md` (same format as verify-django).
