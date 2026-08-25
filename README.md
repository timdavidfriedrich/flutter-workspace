# flutter-workspace

Claude Code plugin plus project template for Flutter workspaces:
`core` ← `shared` ← `features` ← app package, `flutter_bloc`, `go_router`,
`get_it`/`injectable` micro-packages, `dart_mappable`, ARB localization.

> Replace `CHANGE-ME` in [`setup.sh`](setup.sh) with your GitHub owner/repo
> after forking. That is the only place the repo path is hardcoded.

## Install the styleguide plugin

```bash
claude plugin marketplace add CHANGE-ME/flutter-workspace
claude plugin install flutter-styleguide@flutter-workspace
```

The skill is then `/flutter-styleguide:styleguide`, and Claude loads it on its own
when a task touches Dart. Update later with `claude plugin marketplace update`.

Add this line to a project's `CLAUDE.md` if you want the trigger to be
deterministic rather than model-judged (the template already ships it):

```markdown
Before writing or editing any Dart file, invoke the flutter-styleguide skill.
```

## Scaffold a project

Straight from the web, nothing checked out locally:

```bash
curl -fsSL https://raw.githubusercontent.com/CHANGE-ME/flutter-workspace/main/setup.sh \
  | bash -s -- --name my_app --org com.example --title "My App" \
               --platforms android,ios --flutter 3.47.0 --target ~/Code/my_app
```

Or, if you prefer to read the script before running it:

```bash
curl -fsSLO https://raw.githubusercontent.com/CHANGE-ME/flutter-workspace/main/setup.sh
less setup.sh && bash setup.sh --name my_app --org com.example --target ~/Code/my_app
```

From a checkout, `setup.sh` uses the adjacent `template/`; otherwise it fetches
the repo tarball for `--ref` (default `main`) into a temp dir and cleans up after.

| Option | |
|---|---|
| `--name` | Dart package name, `snake_case` (required) |
| `--org` | reverse-DNS org for bundle ids (required) |
| `--title` | human-readable title (default: derived from `--name`) |
| `--platforms` | `flutter create --platforms` (default: `android,ios`) |
| `--flutter` | FVM Flutter version (default: `stable`) |
| `--ref` | template revision to fetch (default: `main`) |
| `--log-git-url` / `--log-git-ref` | pull in `klog` |
| `--target` | target directory, must be empty (default: current) |

The script refuses a non-empty target and ends with `fvm flutter analyze`, so a
green run means the scaffold compiles.

## Why `flutter create` runs before `fvm use`

`fvm use` writes a `.gitignore` containing only `.fvm/`. A later `flutter create`
then **skips** writing its own, leaving the project without `build/`,
`.dart_tool/` and the rest — silently. Reversed, fvm appends to the full Flutter
`.gitignore`. `setup.sh` asserts this afterwards.

`fvm spawn <version> create` is what makes that order safe: it runs a pinned SDK
without needing a `.fvmrc` yet. Plain `fvm flutter` at that point would fall back
to whatever `flutter` is on `PATH` — silently the wrong version. The create step
writes version-dependent artifacts (`.metadata` revision, AGP, Kotlin, Gradle
wrapper, Podfile) that `fvm use` does not retro-fix.

## No version numbers in the template

Every dependency is installed with `fvm flutter pub add`, which writes the current
constraint itself. The template holds only the placeholder `__SDK__` and the
workspace member references, which carry no version by design.

## Layout

```text
.claude-plugin/marketplace.json     marketplace manifest
plugins/flutter-styleguide/         the plugin
  .claude-plugin/plugin.json
  skills/styleguide/                SKILL.md + 11 topic files
setup.sh                            scaffolder
template/                           app + core + shared + feature_home
```

`feature_home` is a complete vertical slice — `RemoteArticle` → mappers → data
source → repository → Bloc → screen — so the architecture is visible once in code.
To drop it, delete `packages/feature_home` and remove its references in
`pubspec.yaml`, `lib/src/di/service_locator.dart`,
`lib/src/navigation/navigation_router.dart`, the `Article` entity plus
`articleDetail`/`pushArticleDetail` in `shared`, and the `home*` ARB keys. There is
deliberately no `--no-example` flag: the DI root and router reference the feature,
so a flag that half-works would be worse than none.

## Verified

Scaffolded clean on Flutter 3.47.0 / Dart 3.13.0 — `dart_mappable` 4.8.0 codegen,
`injectable` micro-package composition across all four packages, `gen-l10n` for
en/de, `flutter analyze` with zero issues, via both a local checkout and
`curl | bash`.

Two ordering constraints CI should keep honest:

- `build_runner` runs in `packages/*` **before** the app package — the app's DI
  config imports each member's generated `*_module.module.dart`.
- `--delete-conflicting-outputs` was removed in `build_runner` 2.16 and is ignored.
