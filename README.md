# flutter-workspace

Scaffolding and styleguide for Flutter pub-workspace projects.

## What it does

Generates a workspace and keeps it wired as it grows:

```text
lib/                     app package: main.dart, DI root, router, theme
packages/core/           AppResult, AppError, Spacing, ThemeExtension, Dio, build config
packages/shared/         ContextExtensions, ARB (en/de), NavigationRoute, entities
packages/feature_home/   example slice: model → mapper → data source → repository → Bloc → screen
```

Stack: `flutter_bloc`, `go_router`, `get_it`/`injectable` micro-packages,
`dart_mappable`, `dio`, [`klog`](https://github.com/timdavidfriedrich/klog). No
dependency version is written by hand. Every one is installed with `pub add`.

It does **not** generate feature logic, screens or models; that is what the
styleguide is for. It does not install FVM or Flutter either.

`feature_home` is an example. To drop it, delete the package and its references in
`pubspec.yaml`, `lib/src/di/service_locator.dart`,
`lib/src/navigation/navigation_router.dart`, the `Article` entity plus
`articleDetail`/`pushArticleDetail` in `shared`, and the `home*` ARB keys.

## Prerequisites

```bash
brew install leoafarias/fvm/fvm
```

FVM fetches the Flutter SDK on demand. Nothing else lives on your machine.

## Installation

Three ways, same scripts underneath. Pick one, or mix them.

| | install |
|---|---|
| **curl** | nothing |
| **[`fsg`](https://github.com/timdavidfriedrich/homebrew-tap#fsg)** | `brew install timdavidfriedrich/tap/fsg` |
| **Claude Code plugin** | `claude plugin marketplace add timdavidfriedrich/flutter-workspace`<br>`claude plugin install flutter-styleguide@flutter-workspace` |

> [!WARNING]
> Only the Claude Code plugin adds the LLM styleguide. Scaffolding works either way,
> but with curl or `fsg` alone your generated code follows no rules.

## Create a project

```bash
fsg create --name my_app --org com.example --target ~/Code/my_app

# or
curl -fsSL https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/setup.sh \
  | bash -s -- --name my_app --org com.example --target ~/Code/my_app

# or, in Claude Code — asks for anything you leave out
/flutter-styleguide:new-project
```

| | |
|---|---|
| `--name` | package name, `snake_case` — required |
| `--org` | reverse-DNS org for bundle ids — required |
| `--target` | must be empty — default: current directory |
| `--title` | default: derived from `--name` |
| `--platforms` | default: `android,ios` |
| `--flutter` | FVM version — default: `stable` |
| `--ref` | template revision — default: `main` |
| `--log-git-url` / `--log-git-ref` | pull in `klog` |

Ends with `fvm flutter analyze`; green means the scaffold compiles. Then:

```bash
cd ~/Code/my_app && fvm flutter run
```

## Add a feature package

Run from the workspace root, or pass `--target <dir>`.

```bash
fsg add-feature scan

# or
curl -fsSL https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/add-feature.sh \
  | bash -s -- scan

# or
/flutter-styleguide:add-feature scan
```

Creates `packages/feature_scan/` and wires the four lines it does not own:

```text
pubspec.yaml          - packages/feature_scan
pubspec.yaml          feature_scan:
service_locator.dart  import '…/feature_scan_module.module.dart';
service_locator.dart  ExternalModule(FeatureScanPackageModule),
```

Aborts before writing anything if the feature exists or the DI root was
restructured. Ends with `fvm flutter analyze`.

## Use the LLM styleguide to generate better code

> [!WARNING]
> Only the Claude Code plugin provides it. `fsg` and curl scaffold projects and
> nothing else.

With the plugin installed, Claude should reach for the styleguide on its own when you ask for a screen, a Bloc, a repository or anything else in Dart. That is a model judgment, so to be sure you can force it with:
```bash
/flutter-styleguide:styleguide
```
The command is also handy for reviewing existing code.

In a project created with this tool, a `CLAUDE.md` instructs Claude to use it as well. To apply the rules to a project you did not scaffold, add that same line to its `CLAUDE.md`:

```markdown
Before writing or editing any Dart file, invoke the `flutter-styleguide:styleguide` skill.
```

Without Claude Code the guide is plain markdown:
[`plugins/flutter-styleguide/skills/styleguide/`](plugins/flutter-styleguide/skills/styleguide/),
`SKILL.md` plus eleven topic files.

Update everything with `claude plugin marketplace update`.
