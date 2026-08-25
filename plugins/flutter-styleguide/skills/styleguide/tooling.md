# Tooling, FVM & Codegen

*Requires `SKILL.md`.*

- **FVM is mandatory.** Every Flutter/Dart command runs through `fvm`, including commands you suggest to the user. Never `flutter ...` or `dart ...` without `fvm`.
- **`pub get` workspace-wide** (one `pubspec.lock`):
  ```bash
  fvm flutter pub get
  fvm flutter run
  ```
- **`build_runner` per package**, member packages **before** the app package — the app's DI config imports their generated micro-package modules. Only where `build_runner` is a dev dependency:
  ```bash
  for package in packages/* .; do
    grep -q "build_runner" "$package/pubspec.yaml" || continue
    (cd "$package" && fvm dart run build_runner build)
  done
  ```
  `--delete-conflicting-outputs` was removed in `build_runner` 2.16 and is ignored.
- **`gen-l10n`** in the package holding the ARB files:
  ```bash
  cd packages/shared && fvm flutter gen-l10n
  ```
- **Codegen triggers:** `build_runner` after changes to `dart_mappable` models/states and DI annotations; `gen-l10n` after ARB changes. Never edit generated files manually (`*.mapper.dart`, `*.config.dart`, `*.module.dart`, `generated/`).
