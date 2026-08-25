# flutter-workspace

Claude Code plugin plus project template for Flutter workspaces:
`core` ← `shared` ← `features` ← app package, `flutter_bloc`, `go_router`,
`get_it`/`injectable` micro-packages, `dart_mappable`, ARB localization.


## On a new machine

Install FVM and a Flutter SDK — that part cannot come from a repo. Everything
else is one command:

```bash
claude plugin marketplace add timdavidfriedrich/flutter-workspace
claude plugin install flutter-styleguide@flutter-workspace
```

That installs three skills:

| | |
|---|---|
| `/flutter-styleguide:new-project` | scaffold a project, wraps `setup.sh` |
| `/flutter-styleguide:add-feature <name>` | add a feature package, wraps `add-feature.sh` |
| `/flutter-styleguide:styleguide` | the coding rules — Claude loads this on its own whenever a task touches Dart |

A session then looks like this:

```text
/flutter-styleguide:new-project          → asks for name, org and target, then scaffolds
"build me a settings screen"             → styleguide loads itself, code follows it
/flutter-styleguide:add-feature scan     → creates and wires packages/feature_scan
"add a barcode scanner to feature_scan"  → same rules apply
```

The scaffolded project ships a `CLAUDE.md` naming the styleguide skill, so the
trigger inside a project is deterministic rather than model-judged. Nothing else
lives on the machine: the two scripts and the template are fetched from this repo
at run time.

Update everything later with `claude plugin marketplace update`. If you had the
skill installed standalone under `~/.claude/skills/flutter-styleguide/`, delete it
after installing the plugin — plugin skills are namespaced, so both would show up.

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
