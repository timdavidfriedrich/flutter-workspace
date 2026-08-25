# flutter-workspace

Claude Code plugin plus project template for Flutter workspaces:
`core` ← `shared` ← `features` ← app package, `flutter_bloc`, `go_router`,
`get_it`/`injectable` micro-packages, `dart_mappable`, ARB localization.


## Install the styleguide plugin

```bash
claude plugin marketplace add timdavidfriedrich/flutter-workspace
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
curl -fsSL https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/setup.sh \
  | bash -s -- --name my_app --org com.example --title "My App" \
               --platforms android,ios --flutter 3.47.0 --target ~/Code/my_app
```

Or, if you prefer to read the script before running it:

```bash
curl -fsSLO https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/setup.sh
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

## Add a feature package

Run the script:

```bash
curl -fsSL https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/add-feature.sh \
  | bash -s -- scan
```

It acts on the current directory; pass `--target <dir>` to point it elsewhere.

Creates `packages/feature_scan/` with its `pubspec.yaml` and DI module, then wires
it into four lines it does not own:

```text
pubspec.yaml          - packages/feature_scan       (workspace list)
pubspec.yaml          feature_scan:                 (app dependency)
service_locator.dart  import '…/feature_scan_module.module.dart';
service_locator.dart  ExternalModule(FeatureScanPackageModule),
```

Unlike `setup.sh`, this edits existing files. Every precondition is checked
before the first write — the feature must not exist, and `workspace:`,
`externalPackageModulesBefore: [` and the `ExternalModule` entries must be
present — so a project whose DI root was restructured aborts with a message
instead of silently doing nothing. Each insertion is verified afterwards, and the
run ends with `fvm flutter analyze`.
