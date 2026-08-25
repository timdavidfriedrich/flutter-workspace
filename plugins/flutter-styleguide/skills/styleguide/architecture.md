# Architecture & File Placement

*Requires `SKILL.md`.*

## Module Types
- `packages/core/`: technical foundation, knows nothing about this app.
- `packages/shared/`: app-specific code needed by several features.
- `packages/feature_<name>/`: one feature, functionally complete.
- App package (root, `lib/`): composition root.

## Module Dependencies
Strict, acyclic, no exception: `core` ← `shared` ← `features` ← `app`
- `core` depends on no module, `shared` only on `core`.
- A feature depends on `core` and `shared`, never on another feature. If feature A needs something from feature B, it moves to `shared`.
- The app package depends on everything; nothing depends on the app package.

## Placement Rule
1. Copyable unchanged into another project? → `core`. `core` contains no app name, route, translated string or brand color.
2. App-specific, needed by several features? → `shared`.
3. Knows the features themselves? → app package. Only the DI root and the `GoRoute` tree qualify.

**Two kinds of cuts, never mixed:**
- `shared` and `features` by **layer**, each layer subdivided by kind:
    - `data/`: `models`, `mappers`, `data_sources`, `repositories`
    - `domain/`: `repositories`, `use_cases` — plus `entities`, which only ever exists in `shared`
    - `presentation/`: Blocs, events, states and screens sit directly in it. `extensions` and `widgets` get their own folder in any package that needs them; `localization` and `navigation` exist only in `shared`.

    Create a subfolder only once a file needs it — never an empty one.
- `core` and app package by **capability**, never by layer — no `core/domain/`:
  - `core`: `config`, `di`, `error`, `network`, `persistence`, `theme`
  - app package: `di`, `navigation`, `theme`

**No barrel files, no `lib/src/` in member packages.** Code sits directly under `lib/`, imported precisely; a file that must be package-private goes into `lib/src/`.
```dart
import 'package:core/error/app_result.dart';
```

- **Extensions and helpers** live in the innermost module that actually uses them — one feature → the feature; several → `shared`; `core` only if `core` code calls it itself. Domain-related extensions live next to the type they extend.
- **Entities always in `shared/domain/entities/`**, no matter how many features use them. `Local*`/`Remote*` models and mappers stay in the package of their data source (`data.md`).

## File Naming

| Suffix / prefix | Meaning | Example |
|---|---|---|
| `_screen.dart` | screen (route target) | `settings_screen.dart` |
| `_bloc.dart` / `_event.dart` / `_state.dart` | Bloc, always 3 separate files | `article_list_bloc.dart` |
| `_cubit.dart` / `_state.dart` | Cubit | `connectivity_cubit.dart` |
| `_repository.dart` | interface in `domain/repositories/` | `article_repository.dart` |
| `_repository_impl.dart` | implementation in `data/repositories/` | `article_repository_impl.dart` |
| `_data_source.dart` / `_data_source_impl.dart` | interface / implementation in `data/data_sources/` | `remote_data_source.dart` |
| `_use_case.dart` | use case in `domain/use_cases/` | `sign_out_use_case.dart` |
| `local_` (prefix) | local persistence model in `data/models/` | `local_article.dart` |
| `remote_` (prefix) | API DTO in `data/models/` | `remote_article.dart` |
| `_extensions.dart` | extensions | `date_time_extensions.dart` |
| `_mappers.dart` | all mappers of one entity | `article_mappers.dart` |
| *(no suffix)* | domain entity, widget | `article.dart`, `avatar_badge.dart` |

Class names follow the file: entity `Article` · local model `LocalArticle` · API DTO `RemoteArticle` · extensions `DateTimeExtensions` · mappers `ArticleMappers`.

## Canonical Placement
These paths are mandatory; if a file does not exist, create it here.

```text
lib/
├── main.dart                                  MaterialApp.router, localizationsDelegates
└── src/
    ├── di/service_locator.dart                sl + configureDependencies()
    ├── navigation/
    │   ├── navigation_router.dart             GoRoute tree + BlocProvider
    │   ├── navigation_shell_container.dart
    │   └── go_router_refresh_stream.dart
    └── theme/app_theme.dart                   concrete ThemeData light/dark

packages/core/lib/
├── config/build_config.dart                   compile-time constants
├── di/core_module.dart
├── error/
│   ├── app_result.dart                        AppResult / Success / Failure
│   └── app_error.dart                         sealed AppError
├── network/                                   Dio setup, interceptors
├── persistence/                               local DB definitions
└── theme/
    ├── spacing.dart                           design tokens
    └── theme_extensions.dart                  ThemeExtension classes

packages/shared/
├── l10n.yaml
└── lib/
    ├── di/shared_module.dart
    ├── domain/entities/                       shared entities
    └── presentation/
        ├── extensions/
        │   ├── context_extensions.dart        s / c / t / showToast
        │   ├── app_error_extensions.dart      toMessage(context)
        │   └── date_time_extensions.dart
        ├── localization/                      *.arb + generated/
        ├── navigation/
        │   ├── routes.dart                    parameterId + NavigationRoute
        │   └── navigation_extensions.dart     context.pushX(...)
        └── widgets/                           reusable components

packages/feature_<name>/lib/
├── di/<name>_module.dart                     @InjectableInit.microPackage()
├── data/
│   ├── data_sources/
│   ├── mappers/
│   ├── models/                               Local* / Remote*
│   └── repositories/                         *_repository_impl.dart
├── domain/
│   ├── repositories/                         abstract interfaces
│   └── use_cases/
└── presentation/
    ├── extensions/                           feature-only extensions
    ├── widgets/                              reused inside this feature
    └── *_bloc.dart / _event.dart / _state.dart / *_screen.dart
```

## Layer Access (strict)
- UI never calls a repository or use case directly — only Bloc/Cubit.
- Bloc/Cubit → use case **or** repository interface.
- Use case → repository interface.
- Repository implementation → data sources.
- `domain/` never imports Flutter UI packages.

## Use Cases
Only for real logic: orchestrating several repositories, rules/validation, or shared by several Blocs. Otherwise inject the repository interface directly into the Bloc — no pass-through use cases.

`@injectable`, dependencies as positional private fields, exactly one public method `call()`, one use case per file.
```dart
@injectable
class SignOutUseCase {
  SignOutUseCase(this._authRepository, this._cacheRepository);

  final AuthRepository _authRepository;
  final CacheRepository _cacheRepository;

  Future<AppResult<()>> call() async {
    final result = await _authRepository.signOut();
    if (result case Failure(:final error)) return Failure(error);
    return _cacheRepository.clear();
  }
}
```
