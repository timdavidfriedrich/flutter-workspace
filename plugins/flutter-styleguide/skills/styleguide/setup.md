# Project Setup

*Workspace, packages and analyzer configuration. Needed when scaffolding a project, adding a member package, or editing `pubspec.yaml` / `analysis_options.yaml`. Coding rules: the `flutter-styleguide` skill.*

## 1. Workspace Structure
Root directory = app package = workspace root. All member packages under `packages/`.

```text
pubspec.yaml                  app package + workspace root, shared versions
analysis_options.yaml         once, applies to all packages
lib/main.dart
lib/src/…
packages/core/
packages/shared/
packages/feature_home/
packages/feature_scan/
```

**Member packages contain only `pubspec.yaml` and `lib/`.** No own `README`, `analysis_options.yaml` or formatter settings. Only exception: `packages/shared/l10n.yaml` (`gen-l10n` resolves relative to the working directory).

## 2. Version Constraints
- Used by several packages → constraint only in the root `pubspec.yaml`; members list it without one.
- Used by one member package → constraint only there, never lifted into the root.
- Member-to-member references always without a constraint.
- **`^<latest>` and `^<sdk>` below are placeholders.** Never write a version by hand and never copy one from an example. Add dependencies only via `fvm flutter pub add <package>` (or `--dev`) in the target package directory — that writes the current constraint itself. `sdk:` matches the FVM-installed Dart version (`.fvmrc`).

## 3. Root `pubspec.yaml`
```yaml
name: my_app
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^<sdk>

workspace:
  - packages/core
  - packages/shared
  - packages/feature_home
  - packages/feature_scan

dependencies:
  flutter:
    sdk: flutter

  core:
  shared:
  feature_home:
  feature_scan:

  dart_mappable: ^<latest>
  dio: ^<latest>
  flutter_bloc: ^<latest>
  flutter_hooks: ^<latest>
  get_it: ^<latest>
  go_router: ^<latest>
  injectable: ^<latest>
  intl: ^<latest>

  klog:
    git:
      url: https://github.com/timdavidfriedrich/klog.git
      ref: v1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^<latest>
  dart_mappable_builder: ^<latest>
  flutter_lints: ^<latest>
  injectable_generator: ^<latest>

flutter:
  uses-material-design: true
```

`klog` is pulled from git, not a workspace member — no folder under `packages/`, no `workspace:` entry. Add it via `fvm flutter pub add klog --git-url=https://github.com/timdavidfriedrich/klog.git --git-ref=<tag>`.

## 4. Member `pubspec.yaml`
```yaml
name: feature_scan
version: 0.0.1
environment:
  sdk: ^<sdk>
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  core:
  shared:
  flutter_bloc:
  flutter_hooks:
  injectable:

  mobile_scanner: ^<latest>

dev_dependencies:
  build_runner:
  injectable_generator:
```

`mobile_scanner` is used only here, hence the constraint. `packages/shared` additionally needs `flutter_localizations` (SDK) and `flutter: generate: true`.

## 5. Adding a Member Package
Folder under `packages/` → member `pubspec.yaml` → add the path to `workspace:` → add the package name at its consumers → `fvm flutter pub get` in the root.

## 6. `analysis_options.yaml`
Exactly one, in the root.

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - avoid_dynamic_calls
    - directives_ordering
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - require_trailing_commas
    - sort_constructors_first
    - unawaited_futures
    - unnecessary_null_checks

formatter:
  page_width: 100
  trailing_commas: preserve
```
