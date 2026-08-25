# Logging & Build Configuration

*Requires `SKILL.md`.*

- **Logging only via the `klog` package** (project-independent, pulled from git — see `setup.md`): `Klog.debug(...)`, `Klog.hint(...)`, `Klog.warning(...)`, `Klog.error(..., exception: ...)`. It writes in debug builds only; `print` is forbidden by lint.
- **Never log** personal data, tokens or full API payloads.
- **Build configuration as top-level `const`** in `core/config/build_config.dart`, read via `bool.fromEnvironment` / `String.fromEnvironment` from `--dart-define`:
  ```dart
  const bool isInDebugMode =
      bool.fromEnvironment("DEBUG_MODE") || kDebugMode || kProfileMode;
  ```
  Compile-time constants only — never read configuration at runtime from files or remote sources.
