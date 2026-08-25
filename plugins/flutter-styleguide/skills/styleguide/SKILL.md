---
description: Mandatory architecture, code style and conventions for this Flutter/Dart project. Use before writing, editing or reviewing any Dart file, and whenever creating a screen, widget, Bloc, Cubit, repository, data source, model, mapper, use case, route, DI registration or ARB string, or when setting up packages, running codegen or touching pubspec.yaml.
---

# Flutter & Dart Styleguide

Follow these rules strictly in all generated code. Read the reference file for the task at hand **before** writing that code. When in doubt, ask.

| Task | Read |
|---|---|
| Creating a file, deciding where code belongs | `architecture.md` |
| Screen, widget, theme, colors, spacing, layout | `ui.md` · `state.md` · `l10n.md` |
| Bloc, Cubit, state class, event, hook | `state.md` |
| Repository, data source, model, mapper, DTO, API call | `data.md` · `architecture.md` |
| Use case | `architecture.md` |
| Route, navigation, deep link, auth gating | `routing.md` · `di.md` |
| Registering or injecting a dependency | `di.md` |
| User-facing string, ARB key, plural | `l10n.md` |
| `DateTime`, duration, number or currency formatting | `datetime.md` |
| Logging, `--dart-define`, build flags | `logging.md` |
| Running a command, codegen, `build_runner` | `tooling.md` |
| New project, new package, `pubspec.yaml`, lints | `setup.md` · `tooling.md` |

## Meta
- **No comments, no documentation** (no `///`, no `//`). Exception: `// *` only for things impossible to understand without context (e.g. a mandatory string format), in English.
- **All identifiers in English.**
- **Use the identifiers defined in this guide** instead of inventing new ones. If one does not exist yet, create it at the location given in `architecture.md`.
- **No tests.** Do not generate test files unless explicitly requested.
- **FVM is mandatory.** Every Flutter/Dart command runs through `fvm`, including commands you suggest to the user. Never `flutter ...` or `dart ...` without `fvm`.

## Hard Boundaries
Violating these is never acceptable, whatever the task:
- UI never calls a repository or use case directly — only Bloc/Cubit.
- Every repository, use case and service method returns `AppResult` (below).
- `domain/` never imports Flutter UI packages.
- No hardcoded user-facing text — always localization (`l10n.md`).
- No magic numbers — top-level private `const` at the top of the file; UI dimensions come from `Spacing` (`ui.md`).
- Never edit generated files (`*.mapper.dart`, `*.config.dart`, `*.module.dart`, `generated/`).

## Dart & Flutter
- **Dart 3:** use pattern matching, records, `sealed` classes for states and exhaustive `switch`.
- **Const-first:** `const` and `final` wherever possible.
- **Strings:** double quotes (`"..."`), except import statements (`'...'`).
- **Primary constructors** (Dart 3.13+), always. `const` goes between `class` and the name. One parameter per line with a trailing comma, even when there is only one — `trailing_commas: preserve` keeps that layout:
  ```dart
  class const Task({
    required final String id,
    required final String title,
  });

  class const ArticleRepositoryImpl(
    final ArticleLocalDataSource _dataSource,
  ) implements ArticleRepository {
    ...
  }
  ```
  A parameter list that is empty stays on one line: `class const HomeLoading() extends HomeState;`
- **Private named parameters** declare the field private while the call site keeps the public name — `AvatarBadge(label: "New")` sets the field `_label`. Use them **only when no other file reads those fields**, because a private field is library-private:
  - **Yes** — widgets, Blocs, Cubits, use cases, services, repository and data source implementations. Their constructor values stay inside the declaring file.
  - **No** — entities, `Local*`/`Remote*` models, Bloc/Cubit states. A mapper in another file cannot read `_id`, and `ProfileLoaded(:final name)` does not destructure a private `_name`.
  ```dart
  class const AvatarBadge({
    required final String _label,
  });
  ```

## Pattern Matching
- **Priority 1 — `switch` expression.** Assignment, return and argument are equally valid; what matters is the expression form, not the statement form.
  ```dart
  final message = switch (result) {
    Success(:final data) => data.title,
    Failure(:final error) => error.toMessage(context),
  };
  ```
- **Priority 2 — `if-case` with early return** for error propagation and guards.
  ```dart
  if (result case Failure(:final error)) return Failure(error);
  ```
- **Priority 3 — `switch` statement** only when a branch needs several statements.

## Naming
- **Files:** `snake_case`. Suffix conventions and placement: `architecture.md`.
- **Classes:** `PascalCase`. Blocs descriptive: `ArticleListBloc`, not `ListBloc`.
- **Packages:** `snake_case` — `core`, `shared`, `feature_<name>`.
- **Variables:** spelled out — `preferences` not `prefs`, `(result) {}` not `(r) {}`.
- **Extensions** live in `_extensions.dart` files, named `<Type>Extensions`.

## Results & Error Handling
Every repository, use case and service method returns `AppResult`.
- `Future<AppResult<T>>` for one-off operations.
- `Future<AppResult<()>>` when there is no return value (record unit, not `void`) → success is `const Success(())`.
- `Stream<AppResult<T>>` for reactive queries (`watchX`).
```dart
abstract class ArticleRepository {
  Stream<AppResult<List<Article>>> watchArticles({String? authorId});
  Future<AppResult<Article>> saveArticle(Article article);
  Future<AppResult<()>> deleteArticle(String id);
}
```

`sealed class AppResult<T>` (`Success<T>(this.data)`, `Failure<T>(this.error)`) and `sealed class AppError`, both from `core/error/`. `AppError` is an open hierarchy: `ConnectionError()`, `ApiError(String message)`, `AuthError()`, `ValidationError()`, `NotFoundError()`, `UnexpectedError([String? message])`.

- No uncontrolled exceptions reach the UI — translate them into `AppError` at the data layer boundary.
- For every new `AppError` (e.g. `CameraPermissionError()`): subclass in `core` → case in `AppErrorExtensions.toMessage(context)` in `shared` → ARB key in all language files (`l10n.md`).
- In the UI always `error.toMessage(context)`.
