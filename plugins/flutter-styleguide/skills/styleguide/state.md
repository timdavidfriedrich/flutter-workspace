# State Management

*Requires `SKILL.md`.*

- **Tool:** `flutter_bloc`. **Bloc** for screens and anything with an event history; **Cubit** for small shared widget state, with direct methods instead of event classes.
- **File split:** always `<name>_bloc.dart` + `<name>_event.dart` + `<name>_state.dart`. No combined file, no `part` directives.
- **States:** `sealed` classes with **public** named parameters (widgets destructure them via pattern matching from another file), value equality via `dart_mappable` codegen — no `equatable`.
- **Events:** past tense (`ProfileStarted`, `ProfileRefreshed`, `ProfileItemToggled`), handlers `_onStarted`, `_onRefreshed`, `_onItemToggled`.
  ```dart
  ProfileBloc(this._repository) : super(const ProfileLoading()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileRefreshed>(_onRefreshed);
  }
  ```
- **Granularity:** fine-grained UI updates inside a state are allowed (e.g. a loading spinner on a single button, which can set back to not loading).
- **UI consumes states via exhaustive pattern matching:**
  ```dart
  BlocBuilder<ProfileBloc, ProfileState>(
    builder: (context, state) => switch (state) {
      ProfileLoading() => const Center(child: CircularProgressIndicator()),
      ProfileFailure(:final error) => _ErrorView(error: error),
      ProfileLoaded() => _Content(state: state),
    },
  )
  ```
- **`BlocProvider` in the route tree, not in the screen.** Screens stay pure `StatelessWidget`s without DI knowledge and without knowing their start event.
  ```dart
  GoRoute(
    path: NavigationRoute.profile.path,
    builder: (context, state) => BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(const ProfileStarted()),
      child: const ProfileScreen(),
    ),
  )
  ```
  Cubits shared across the shell: `MultiBlocProvider` around the `StatefulNavigationShell`.
- **Widgets get Blocs via `BlocProvider` / `context.read<T>()`**, never via `sl` (`di.md`).
- **Hooks:** `flutter_hooks` for local UI state (controllers, animations, simple toggles) instead of `StatefulWidget`s. Hook state never goes into a Bloc, Bloc state never into a hook.
- **Bloc/Cubit calls** a use case or a repository interface, never a data source (`architecture.md`).
