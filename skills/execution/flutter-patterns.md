# Skill: Flutter Patterns

## Purpose
Guide Claude Code when implementing Flutter/Dart features.

## Project Structure
- Feature-based organization: `lib/features/[feature_name]/`
- Each feature contains: `models/`, `providers/` or `blocs/`, `screens/`, `widgets/`, `services/`
- Shared code in `lib/core/` (networking, theme, utils, constants)
- API layer in `lib/core/api/`

## State Management
- Follow whatever the project uses (Riverpod, Bloc, Provider)
- Keep state classes immutable where possible
- Separate UI state from business logic
- Use AsyncValue/AsyncNotifier patterns for API-driven state (Riverpod)

## Models
- Use freezed + json_serializable for data classes
- Models should mirror API response shapes
- Keep `fromJson` / `toJson` generated — don't hand-write them
- Separate domain models from API DTOs when shapes diverge significantly

## Widgets
- Small, focused widgets — extract early
- Prefer composition over inheritance
- Use `const` constructors wherever possible
- Avoid deep widget nesting — extract methods or widgets at 3-4 levels

## Navigation
- Use GoRouter (or project's chosen solution)
- Type-safe routes with route constants
- Handle deep linking from the start

## API Integration
- Centralized API client using Dio or http package
- Interceptors for auth token injection and refresh
- Typed response parsing at the API layer
- Error handling with custom exception types

## Testing
- Unit tests for business logic and state management
- Widget tests for component behavior
- Integration tests for critical user flows
- Use mocktail for mocking

## Working from Integration Summaries
When starting Flutter frontend work from a backend integration summary:
1. Generate freezed model classes matching response shapes
2. Build the API service functions first
3. Create a repository layer that handles caching/error mapping
4. Verify against the real API before building UI
5. Flag any discrepancies between the summary and actual API behavior
