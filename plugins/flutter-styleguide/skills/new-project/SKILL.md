---
description: Scaffold a new Flutter workspace project from the flutter-workspace template. Use when the user explicitly asks to create, start or set up a new Flutter project. Not for adding to an existing one.
---

# New Flutter Project

Scaffolds a pub-workspace project that follows the styleguide: `core` ← `shared`
← `features` ← app package, with `flutter_bloc`, `go_router`, `injectable`
micro-packages, `dart_mappable` and ARB localization already wired.

## Parameters

Ask the user for anything not given. Required:

| | |
|---|---|
| `--name` | Dart package name, `snake_case`, no dashes (e.g. `field_notes`) |
| `--org` | reverse-DNS org for bundle ids (e.g. `com.example`) |
| `--target` | directory to create the project in — must be empty or not exist |

Optional, only pass when the user names one:

| | |
|---|---|
| `--title` | human-readable app title (default: derived from `--name`) |
| `--platforms` | default `android,ios`; e.g. `android,ios,web` |
| `--flutter` | FVM version, default `stable`; `fvm list` shows what is installed |
| `--log-git-url` / `--log-git-ref` | pull in the `klog` logging package |

## Run

```bash
curl -fsSL https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/setup.sh \
  | bash -s -- --name <name> --org <org> --target <target>
```

Requires `fvm` on PATH. The script creates the platform folders with
`fvm spawn <version> create`, copies the template over them, installs every
dependency with `pub add` (so no version is ever hand-written), runs `gen-l10n`
and `build_runner`, and ends with `fvm flutter analyze`.

## After it finishes

A green `flutter analyze` means the scaffold compiles. Report the path and that
`fvm flutter run` is the next step.

The project ships a `CLAUDE.md` that points at the styleguide skill, so code
written in that directory follows it from then on. `feature_home` is a complete
example slice — entity, DTO, mapper, data source, repository, Bloc, screen —
kept so the architecture is visible in code. Offer to remove it once the user has
their own first feature; the README lists what to unwire.

## Do not

- Run this inside an existing project. It refuses a non-empty target, but check first.
- Hand-write version numbers into any `pubspec.yaml`. Use `fvm flutter pub add`.
- Re-run it to "fix" a broken scaffold — read the error, it names the step.
