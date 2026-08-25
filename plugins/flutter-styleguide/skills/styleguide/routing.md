# Routing

*Requires `SKILL.md`.*

- **Tool:** `go_router`. `shared`: `routes.dart`, `navigation_extensions.dart`. App package: `navigation_router.dart`, `navigation_shell_container.dart`, `go_router_refresh_stream.dart`.
- **Implementation:**
  - Encapsulated in a `NavigationRouter` class (`@singleton`), injected into `MaterialApp.router` via `get_it`/`injectable`.
  - `NavigationRoute` enum (with a `String` parameter) for all paths.
  - Root navigator key as top-level private `final` with a `debugLabel`: `final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: "root");`
  - `StatefulNavigationShell` inside a `StatelessWidget` named `NavigationShellContainer`.
  - In `MaterialApp.router`: `onGenerateTitle: (context) => context.s.appTitle` and `supportedLocales: AppLocalizations.supportedLocales`.
- **Path parameters:** top-level `const parameterId = "id";` — without the colon, so the same constant works in the path (`":$parameterId"`), when building a url, and as the key for `state.pathParameters`. Never a hardcoded `"id"` in two places.
  ```dart
  const parameterId = "id";

  enum NavigationRoute {
    home("/home"),
    articles("/articles"),
    articleDetail("/articles/:$parameterId");

    const NavigationRoute(this.path);
    final String path;
  }
  ```
- **Typed navigation:** path strings are never built at the call site but encapsulated in `NavigationExtension on BuildContext`. Inside the router and the extension use the `.path` property; never `context.push("/...")`.
  ```dart
  extension NavigationExtension on BuildContext {
    void pushArticleDetail({required String articleId}) => push(
      NavigationRoute.articleDetail.path.replaceFirst(":$parameterId", articleId),
    );
  }
  ```
- **Every route in the enum must be registered.** A detail route is a child of its
  list route, reads its argument with `state.pathParameters[parameterId]` and passes
  it to the Bloc via `@factoryParam`:
  ```dart
  GoRoute(
    path: NavigationRoute.home.path,
    builder: (context, state) => BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
      child: const HomeScreen(),
    ),
    routes: [
      GoRoute(
        path: ":$parameterId",
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ArticleDetailBloc>(
            param1: state.pathParameters[parameterId],
          )..add(const ArticleDetailStarted()),
          child: const ArticleDetailScreen(),
        ),
      ),
    ],
  )
  ```
- **Redirect `/` to the start route**, otherwise the root location has no match:
  ```dart
  redirect: (context, state) =>
      state.uri.path == "/" ? NavigationRoute.home.path : null,
  ```
- **`BlocProvider` lives in the route tree, not in the screen** (`state.md`):
  ```dart
  GoRoute(
    path: NavigationRoute.profile.path,
    builder: (context, state) => BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(const ProfileStarted()),
      child: const ProfileScreen(),
    ),
  )
  ```
- **Auth gating in the router, not in the UI:** `refreshListenable: GoRouterRefreshStream(_authRepository.watchAuthStatus())` plus a `redirect` callback per `AuthStatus` (`unknown` → loading route, `unauthenticated` → sign-in, `authenticated` → target). `GoRouterRefreshStream` is a `ChangeNotifier` adapter over the stream.
