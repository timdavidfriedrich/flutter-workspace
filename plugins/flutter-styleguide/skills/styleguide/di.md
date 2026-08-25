# Dependency Injection

*Requires `SKILL.md`.*

- **Tools:** `get_it` + `injectable`. Composition root in `lib/src/di/service_locator.dart`:
  ```dart
  final sl = GetIt.instance;

  @InjectableInit()
  Future<void> configureDependencies() async => sl.init();
  ```
- **Across package boundaries:** every package generates its own module (`@InjectableInit.microPackage()`); the app package composes them via `externalPackageModulesBefore`. Take the generated class names from `<package>.module.dart` after the first `build_runner` run, do not guess them.
- **Annotations:**
  - `@injectable` — Blocs, Cubits, use cases, repository implementations, data source implementations.
  - `@lazySingleton` — services, clients, database, router.
  - `@singleton` — only when the instance must exist at startup.
  - `@Injectable(as: ArticleRepository)` — register against the **interface**; always inject the interface, never the `*Impl` class.
  - `@module` — foreign instances without annotations (`Dio`, `SharedPreferences`) and multi-bindings (`List<SomeHandler>`).
- **Constructor injection, positional, private fields.**
- **`sl<...>()` is app-package-internal** and not importable from `core`, `shared` or `features`. Inside the app package only in three places: the router (including `@factoryParam` calls such as `sl<ChatBloc>(param1: id)`), `main.dart`, and top-level entrypoints without a constructor (background handlers, isolate entrypoints).
- **Widgets get Blocs via `BlocProvider` / `context.read<T>()`**, never via `sl`.
- **After every DI change:** `build_runner` in the affected package **and** in the app package (`tooling.md`).
