# Skill: Flutter Patterns

## Purpose
Guide Claude Code when implementing Flutter features in a Django-paired project. Follow these conventions unless the project's CLAUDE.md overrides them.

## Project Structure

```
lib/
├── main.dart
├── config/
│   ├── env.dart                    # Compile-time env (--dart-define)
│   └── constants.dart              # App-wide constants
├── core/
│   ├── api/                        # Dio client, interceptors
│   ├── error/                      # Sealed Failure hierarchy
│   ├── router/                     # GoRouter, auth guard
│   ├── theme/                      # Material 3 ThemeData
│   ├── providers/                  # App-level (session, auth state)
│   ├── utils/                      # Validation, formatting
│   └── widgets/                    # BaseScreen, shared dialogs
├── features/
│   └── {feature}/
│       ├── models/                 # Freezed data classes
│       ├── services/               # Interface + Django impl
│       ├── providers/              # Riverpod state
│       ├── screens/                # Full-page widgets
│       └── widgets/                # Feature-specific widgets
```

**Naming conventions:**
- Files: `snake_case.dart` (e.g. `book_service_django.dart`)
- Classes: `PascalCase` (e.g. `BookServiceDjango`)
- Features: singular noun (`profile`, `book`, `auth`)
- Screens: `{feature}_{action}_screen.dart` (`book_list_screen.dart`, `book_edit_screen.dart`)
- Generated files: co-located (`book.freezed.dart`, `book.g.dart`, `book_providers.g.dart`)

## Models

Use Freezed with `json_serializable`. Models mirror API response shapes.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
class Book with _$Book {
  const Book._();

  factory Book({
    @JsonKey(includeToJson: false) int? id,
    required String title,
    required String author,
    @JsonKey(name: 'published_date') required DateTime publishedDate,
    String? description,
    @JsonKey(name: 'cover_url') String? coverUrl,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  factory Book.empty() => Book(
        title: '',
        author: '',
        publishedDate: DateTime.now(),
      );

  bool get exists => id != null;
}
```

**Conventions:**
- `const Book._()` private constructor enables custom getters/methods
- `@JsonKey(name: ...)` for snake_case API fields
- `@JsonKey(includeToJson: false)` for server-managed fields like `id`
- `factory Book.empty()` for form initialization
- `bool get exists` for create-vs-update logic
- Keep models flat — no nested domain/data split

## Services

Abstract interface defines the contract. One concrete implementation per backend.

```dart
// book_service.dart
abstract class BookService {
  Future<PaginatedResponse<Book>> list({required int page, int limit = 20});
  Future<Book> retrieve(int id);
  Future<Book> save(Book book);
  Future<void> delete(int id);
}
```

```dart
// book_service_django.dart
class BookServiceDjango implements BookService {
  final DioClient client;

  BookServiceDjango(this.client);

  @override
  Future<PaginatedResponse<Book>> list({required int page, int limit = 20}) async {
    final response = await client.get(
      '/books/',
      queryParameters: {'page': page, 'limit': limit, 'ordering': '-created_at'},
    );
    final results = (response['results'] as List)
        .map((json) => Book.fromJson(json))
        .toList();
    return PaginatedResponse(
      page: response['page'],
      count: response['count'],
      numPages: response['num_pages'],
      results: results,
    );
  }

  @override
  Future<Book> retrieve(int id) async {
    final response = await client.get('/books/$id/');
    return Book.fromJson(response);
  }

  @override
  Future<Book> save(Book book) async {
    if (book.exists) {
      final response = await client.patch('/books/${book.id}/', data: book.toJson());
      return Book.fromJson(response);
    }
    final response = await client.post('/books/', data: book.toJson());
    return Book.fromJson(response);
  }

  @override
  Future<void> delete(int id) async {
    await client.delete('/books/$id/');
  }
}
```

**Conventions:**
- Services throw typed `Failure` exceptions (see Error Handling)
- `save()` combines create + update using `model.exists`
- No `Either`/`fpdart` — use `AsyncValue` for error handling at the provider level
- One service per feature, one implementation per backend

## Providers

Use `@riverpod` codegen everywhere. `AsyncNotifier` for stateful operations. Simple functional providers for reads.

### Service binding

```dart
// book_service_provider.dart
@riverpod
BookService bookService(Ref ref) {
  return BookServiceDjango(ref.watch(dioClientProvider));
}
```

### Detail provider (functional)

```dart
// book_detail_provider.dart
@riverpod
Future<Book> bookDetail(Ref ref, int id) async {
  return ref.watch(bookServiceProvider).retrieve(id);
}
```

### List provider (AsyncNotifier)

```dart
// book_list_provider.dart
@riverpod
class BookList extends _$BookList {
  int _page = 1;

  @override
  Future<PaginatedResponse<Book>> build() => _fetch();

  Future<PaginatedResponse<Book>> _fetch() {
    return ref.read(bookServiceProvider).list(page: _page);
  }

  Future<void> loadPage(int page) async {
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> refresh() async {
    _page = 1;
    ref.invalidateSelf();
  }
}
```

### Form provider (Notifier)

```dart
// book_form_provider.dart
@Riverpod(keepAlive: true)
class BookForm extends _$BookForm {
  @override
  Book build() => Book.empty();

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final authorController = TextEditingController();

  void load(Book book) {
    state = book;
    titleController.text = book.title;
    authorController.text = book.author;
  }

  void reset() {
    state = Book.empty();
    titleController.clear();
    authorController.clear();
  }

  Future<bool> submit() async {
    if (!formKey.currentState!.validate()) return false;

    final book = state.copyWith(
      title: titleController.text,
      author: authorController.text,
    );

    try {
      final saved = await ref.read(bookServiceProvider).save(book);
      state = saved;
      reset();
      ref.invalidate(bookListProvider);
      if (saved.id != null) ref.invalidate(bookDetailProvider(saved.id!));
      return true;
    } on Failure catch (e) {
      // Surface error to UI via snackbar or dialog — don't swallow
      rethrow;
    }
  }

  Future<bool> delete() async {
    if (state.id == null) return false;
    await ref.read(bookServiceProvider).delete(state.id!);
    reset();
    ref.invalidate(bookListProvider);
    return true;
  }
}
```

**Conventions:**
- `@riverpod` (lowercase) for auto-dispose providers — most reads
- `@Riverpod(keepAlive: true)` for forms and auth state that survive navigation
- `AsyncValue.guard()` for wrapping async calls in list/detail providers
- Form providers own `TextEditingController`s and `GlobalKey<FormState>`
- After mutation, `ref.invalidate()` related list/detail providers

## Screens

Screens extend `BaseScreen`, which provides `Scaffold` with responsive breakpoint support.

```dart
class BookListScreen extends BaseScreen {
  static String route() => '/books';

  const BookListScreen({super.key});

  @override
  AppBar? appBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('Books'),
      actions: [
        IconButton(
          onPressed: () {
            ref.read(bookFormProvider.notifier).reset();
            context.push(BookEditScreen.routeNew());
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    return const BookInfiniteListWidget();
  }
}
```

```dart
class BookDetailScreen extends BaseScreen {
  final int bookId;
  static String route([int? id]) => '/books/${id ?? ':id'}';

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    final data = ref.watch(bookDetailProvider(bookId));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (book) => BookDetailWidget(book: book),
    );
  }
}
```

**Conventions:**
- Static `route()` method returns the path string
- Consume providers with `ref.watch()` in `body()`, `ref.read()` for actions
- Use `AsyncValue.when()` to handle loading/error/data states
- Override `bodyMd()` / `bodyLg()` only when layout differs at breakpoints

### BaseScreen

```dart
abstract class BaseScreen extends ConsumerWidget {
  final double horizontalPadding;
  final double verticalPadding;

  const BaseScreen({super.key, this.horizontalPadding = 16, this.verticalPadding = 8});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBar(context, ref),
      floatingActionButton: floatingActionButton(context, ref),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: body(context, ref),
      ),
    );
  }

  AppBar? appBar(BuildContext context, WidgetRef ref) => null;
  FloatingActionButton? floatingActionButton(BuildContext context, WidgetRef ref) => null;
  Widget body(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
```

## Widgets

### Extraction rules
- Extract when a widget exceeds ~40 lines or is reused
- One widget per file in `widgets/`
- Prefer `const` constructors — all fields `final`
- Compose widgets, never inherit (except `BaseScreen`)

### Consuming providers in widgets

```dart
class BookListTile extends ConsumerWidget {
  final Book book;
  const BookListTile({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(book.title),
      subtitle: Text(book.author),
      onTap: () => context.push(BookDetailScreen.route(book.id)),
    );
  }
}
```

**Conventions:**
- Pass data down as constructor params when possible
- Use `ConsumerWidget` only when the widget needs `ref`
- Avoid deep nesting — extract sub-widgets at 3-4 levels

## API Client

Singleton Dio instance with interceptor chain: auth, token refresh, logging.

```dart
class DioClient {
  final Dio _dio;

  DioClient({required String baseUrl, required Session session}) : _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  ) {
    _dio.interceptors.addAll([
      _authInterceptor(session),
      if (kDebugMode) _loggingInterceptor(),
    ]);
  }

  Interceptor _authInterceptor(SessionProvider session) {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = session.token;
        if (token != null) {
          if (token.accessIsExpired && !token.refreshIsExpired) {
            final newToken = await _refreshToken(token.refresh);
            session.setToken(newToken);
            options.headers['Authorization'] = 'Bearer ${newToken.access}';
          } else {
            options.headers['Authorization'] = 'Bearer ${token.access}';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          session.clearToken();
        }
        handler.next(error);
      },
    );
  }

  Interceptor _loggingInterceptor() {
    return LogInterceptor(requestBody: true, responseBody: true);
  }

  Future<SessionToken> _refreshToken(String refreshToken) async {
    final response = await Dio(BaseOptions(baseUrl: _dio.options.baseUrl))
        .post('/auth/token/refresh/', data: {'refresh': refreshToken});
    return SessionToken.fromJson(response.data);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data;
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.patch(path, data: data);
    return response.data;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
```

**Conventions:**
- Single `Dio` instance — no per-request construction
- Timeouts configured at construction
- Token refresh in the auth interceptor, not scattered across services
- `LogInterceptor` gated behind `kDebugMode` — no raw `print()`
- Throw `DioException` — services convert to typed `Failure`

## Auth

JWT session with secure storage, auth state provider, and router guard.

### Session provider

```dart
@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  SessionToken? build() => null;

  Future<void> initialize() async {
    final storage = ref.read(storageProvider);
    final access = await storage.read(key: 'access_token');
    final refresh = await storage.read(key: 'refresh_token');
    if (access != null && refresh != null) {
      state = SessionToken(access: access, refresh: refresh);
    }
  }

  void setToken(SessionToken token) {
    state = token;
    final storage = ref.read(storageProvider);
    storage.write(key: 'access_token', value: token.access);
    storage.write(key: 'refresh_token', value: token.refresh);
  }

  void clearToken() {
    state = null;
    final storage = ref.read(storageProvider);
    storage.delete(key: 'access_token');
    storage.delete(key: 'refresh_token');
  }
}
```

### Auth notifier

```dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  FutureOr<User?> build() async {
    await ref.read(sessionProvider.notifier).initialize();
    if (ref.read(sessionProvider) == null) return null;
    return ref.read(authServiceProvider).currentUser();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authServiceProvider).login(email: email, password: password);
      return user;
    });
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    ref.read(sessionProvider.notifier).clearToken();
    state = const AsyncData(null);
  }
}
```

### Route guard

```dart
@riverpod
GoRouter router(Ref ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/books',
    redirect: (context, routerState) {
      final isLoggedIn = auth.valueOrNull != null;
      final isAuthRoute = routerState.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/books';
      return null;
    },
    routes: [/* ... */],
  );
}
```

**Conventions:**
- Use `flutter_secure_storage` for token persistence
- Auth provider uses `AsyncValue<User?>` — null means logged out
- Router watches auth provider and rebuilds on auth state changes
- Session provider is keepAlive — survives navigation

## Error Handling

Sealed `Failure` class hierarchy. Services throw typed failures. Providers surface via `AsyncValue.error`.

```dart
sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}
```

### Converting DioException to Failure (in DioClient or a helper)

```dart
Failure mapDioException(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return const NetworkFailure();
  }
  final statusCode = e.response?.statusCode;
  if (statusCode == 401 || statusCode == 403) {
    return AuthFailure(e.response?.data?['detail'] ?? 'Authentication failed');
  }
  if (statusCode == 400) {
    return ValidationFailure(
      'Validation error',
      fieldErrors: _parseFieldErrors(e.response?.data),
    );
  }
  return ServerFailure(
    e.response?.data?['detail'] ?? 'Server error',
    statusCode: statusCode,
  );
}
```

### Surfacing errors in UI

```dart
// In a screen or widget:
ref.listen(bookListProvider, (prev, next) {
  if (next is AsyncError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.error.toString())),
    );
  }
});
```

**Conventions:**
- Services catch `DioException` and throw typed `Failure`
- Providers use `AsyncValue.guard()` — failures surface as `AsyncError`
- UI uses `ref.listen()` or `AsyncValue.when()` to display errors
- No `Either`/`fpdart` — `AsyncValue` handles the loading/error/data tri-state

## Forms

`AsyncNotifier`-based form providers own controllers and validation. Submission returns `bool` for navigation.

### Form provider pattern (see Providers section for full example)

Key points:
- `TextEditingController` + `GlobalKey<FormState>` live on the notifier
- `load(Model)` populates controllers from existing data
- `reset()` clears everything for a fresh form
- `submit()` validates, calls service, invalidates related providers, returns success
- `keepAlive: true` so form state survives back-navigation during editing

### Form widget

```dart
class BookFormWidget extends ConsumerWidget {
  const BookFormWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookFormProvider.notifier);
    final book = ref.watch(bookFormProvider);

    return Form(
      key: notifier.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: notifier.titleController,
            validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextFormField(
            controller: notifier.authorController,
            decoration: const InputDecoration(labelText: 'Author'),
          ),
        ],
      ),
    );
  }
}
```

### Edit screen with submit

```dart
class BookEditScreen extends BaseScreen {
  final int? bookId;
  static String route([int? id]) => '/books/edit/${id ?? ':id'}';
  static String routeNew() => '/books/new';

  const BookEditScreen({super.key, this.bookId});

  @override
  AppBar? appBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text(bookId != null ? 'Edit Book' : 'New Book'),
      actions: [
        IconButton(
          onPressed: () async {
            final success = await ref.read(bookFormProvider.notifier).submit();
            if (success && context.mounted) context.pop();
          },
          icon: const Icon(Icons.check),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: BookFormWidget(),
      ),
    );
  }
}
```

### Image upload

Use `image_picker` for selection. Upload to the backend's asset endpoint, receive a URL, store it on the model.

```dart
Future<void> pickAndUploadImage(WidgetRef ref) async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  final bytes = await picked.readAsBytes();
  final url = await ref.read(assetServiceProvider).upload(
    filename: picked.name,
    bytes: bytes,
  );
  // Store url on the form model via the form provider
}
```

## Lists

Two patterns: paginated (page controls) and infinite scroll (load-more).

### Paginated list provider

See the `BookList` `AsyncNotifier` in the Providers section. UI consumes with:

```dart
final data = ref.watch(bookListProvider);
data.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text(e.toString()),
  data: (paginated) => Column(
    children: [
      ListView.builder(
        shrinkWrap: true,
        itemCount: paginated.results.length,
        itemBuilder: (context, i) => BookListTile(book: paginated.results[i]),
      ),
      // Page controls
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (paginated.page > 1)
            TextButton(
              onPressed: () => ref.read(bookListProvider.notifier).loadPage(paginated.page - 1),
              child: const Text('Previous'),
            ),
          Text('Page ${paginated.page} of ${paginated.numPages}'),
          if (paginated.page < paginated.numPages)
            TextButton(
              onPressed: () => ref.read(bookListProvider.notifier).loadPage(paginated.page + 1),
              child: const Text('Next'),
            ),
        ],
      ),
    ],
  ),
);
```

### Infinite scroll

Use the `infinite_scroll_pagination` package with a Riverpod provider managing the `PagingController`.

```dart
@Riverpod(keepAlive: true)
class BookInfiniteList extends _$BookInfiniteList {
  final pagingController = PagingController<int, Book>(firstPageKey: 1);

  @override
  void build() {
    pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final data = await ref.read(bookServiceProvider).list(page: page);
      if (data.page >= data.numPages) {
        pagingController.appendLastPage(data.results);
      } else {
        pagingController.appendPage(data.results, page + 1);
      }
    } on Failure catch (e) {
      pagingController.error = e.message;
    }
  }

  void refresh() => pagingController.refresh();
}
```

Widget:

```dart
class BookInfiniteListWidget extends ConsumerWidget {
  const BookInfiniteListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(bookInfiniteListProvider.notifier).pagingController;

    return RefreshIndicator(
      onRefresh: () async => ref.read(bookInfiniteListProvider.notifier).refresh(),
      child: PagedListView<int, Book>(
        pagingController: controller,
        builderDelegate: PagedChildBuilderDelegate<Book>(
          itemBuilder: (context, book, index) => BookListTile(book: book),
          noItemsFoundIndicatorBuilder: (_) => const Center(child: Text('No books found')),
        ),
      ),
    );
  }
}
```

### PaginatedResponse model

```dart
class PaginatedResponse<T> {
  final int page;
  final int count;
  final int numPages;
  final List<T> results;

  const PaginatedResponse({
    required this.page,
    required this.count,
    required this.numPages,
    required this.results,
  });

  bool get canLoadMore => page < numPages;
}
```

### Filtering and ordering

Pass filter/order params through the service and into query parameters:

```dart
Future<PaginatedResponse<Book>> list({
  required int page,
  int limit = 20,
  String? search,
  String ordering = '-created_at',
}) async {
  final response = await client.get('/books/', queryParameters: {
    'page': page,
    'limit': limit,
    'ordering': ordering,
    if (search != null) 'search': search,
  });
  // ... parse response
}
```

## Testing

### Unit tests (services and providers)

```dart
// Mock the service
class MockBookService extends Mock implements BookService {}

void main() {
  late MockBookService mockService;

  setUp(() {
    mockService = MockBookService();
  });

  test('retrieve returns book', () async {
    final book = Book(id: 1, title: 'Test', author: 'Author', publishedDate: DateTime.now());
    when(() => mockService.retrieve(1)).thenAnswer((_) async => book);

    final result = await mockService.retrieve(1);
    expect(result.title, 'Test');
  });
}
```

### Widget tests

```dart
void main() {
  testWidgets('BookListTile displays title and author', (tester) async {
    final book = Book(id: 1, title: 'My Book', author: 'Jane', publishedDate: DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: Scaffold(body: BookListTile(book: book))),
      ),
    );

    expect(find.text('My Book'), findsOneWidget);
    expect(find.text('Jane'), findsOneWidget);
  });
}
```

### Provider tests

```dart
void main() {
  test('bookDetail returns data', () async {
    final container = ProviderContainer(
      overrides: [
        bookServiceProvider.overrideWithValue(MockBookService()),
      ],
    );

    // Set up mock responses, then test provider output
  });
}
```

**Conventions:**
- Use `mocktail` for mocking (not `mockito`)
- Override service providers in tests — never mock Dio directly
- Widget tests wrap with `ProviderScope` + `MaterialApp`
- Test behavior, not implementation — assert what the user sees

## Working from Integration Summaries

When starting Flutter frontend work from a backend integration summary:
1. Generate Freezed model classes matching response shapes
2. Build the service interface + Django implementation
3. Wire up providers (service binding, list, detail, form)
4. Build screens and widgets
5. Verify against the real API before polishing UI
6. Flag any discrepancies between the summary and actual API behavior
