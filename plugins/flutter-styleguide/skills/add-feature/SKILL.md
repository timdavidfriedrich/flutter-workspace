---
description: Add a feature package to an existing Flutter workspace and wire it into the workspace list, app dependencies and DI composition root. Use when the user asks for a new feature, module or package in a project scaffolded from the flutter-workspace template.
---

# Add a Feature Package

Creates `packages/feature_<name>/` and wires it into the four lines it does not
own — the workspace list, the app dependency, the DI import and the
`ExternalModule` registration.

## Parameters

The feature name, `snake_case`, **without** the `feature_` prefix. `$ARGUMENTS`
holds it when the user passed one; otherwise ask.

`scan` → `packages/feature_scan`, module class `FeatureScanPackageModule`.

## Run

From the workspace root:

```bash
curl -fsSL https://raw.githubusercontent.com/timdavidfriedrich/flutter-workspace/main/add-feature.sh \
  | bash -s -- <name>
```

Pass `--target <dir>` if the shell is not already at the workspace root.

The script checks every precondition before writing anything — the feature must
not exist, and `workspace:`, `externalPackageModulesBefore: [` and the existing
`ExternalModule` entries must be present. It verifies each insertion, runs
`build_runner` in the new package before the app package, and ends with
`fvm flutter analyze`.

If it aborts because an anchor is missing, the project's DI root was
restructured. Wire the feature by hand following the four lines above rather than
forcing the script.

## After it finishes

The package contains only `pubspec.yaml` and `lib/di/<pkg>_module.dart`. No
`data/`, `domain/` or `presentation/` folders — the styleguide creates a
subfolder only once a file needs it.

Ask what the feature does, then write its first files following the styleguide:
repository interface in `domain/`, implementation and models in `data/`, Bloc and
screen in `presentation/`. Add its route to the app's `GoRoute` tree and its
strings to every ARB file. Run `build_runner` in the package and the app package
afterwards, in that order.
