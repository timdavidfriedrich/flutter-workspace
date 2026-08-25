#!/usr/bin/env bash
# Adds a feature package to an existing workspace and wires it into the
# workspace list, the app dependencies and the DI composition root.
#
# Unlike setup.sh this edits existing files, so every insertion is verified
# afterwards and the script aborts loudly rather than silently doing nothing.
set -euo pipefail

NAME=""
TARGET="."

usage() {
  cat <<'USAGE'
Usage: ./add-feature.sh <name> [--target <dir>]

  <name>              feature name, snake_case, without the feature_ prefix
                      (e.g. "scan" creates packages/feature_scan)
  --target <dir>      workspace root (default: current directory)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $1" >&2; usage; exit 1 ;;
    *) [[ -z "$NAME" ]] || { echo "unexpected argument: $1" >&2; exit 1; }
       NAME="$1"; shift ;;
  esac
done

[[ -n "$NAME" ]] || { usage; exit 1; }
[[ "$NAME" =~ ^[a-z][a-z0-9_]*$ ]] || {
  echo "name must be snake_case and start with a letter: '$NAME'" >&2; exit 1
}
[[ "$NAME" != feature_* ]] || {
  echo "pass the name without the feature_ prefix (e.g. 'scan', not '$NAME')" >&2; exit 1
}
command -v fvm >/dev/null || { echo "fvm not on PATH" >&2; exit 1; }

PKG="feature_$NAME"
CLASS="$(printf '%s' "$PKG" | awk -F_ '{for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), substr($i, 2)}')"
MODULE="${CLASS}PackageModule"
INIT="init${CLASS}Package"

cd "$TARGET"
ROOT="$PWD"
LOCATOR="lib/src/di/service_locator.dart"

# ------------------------------------------------------------------ preconditions
[[ -f pubspec.yaml ]] || { echo "no pubspec.yaml in $ROOT" >&2; exit 1; }
grep -q '^workspace:' pubspec.yaml || {
  echo "$ROOT/pubspec.yaml has no 'workspace:' section — not a workspace root" >&2; exit 1
}
[[ -f "$LOCATOR" ]] || { echo "$LOCATOR not found" >&2; exit 1; }
[[ ! -d "packages/$PKG" ]] || { echo "packages/$PKG already exists" >&2; exit 1; }

grep -qE '^  - packages/' pubspec.yaml || {
  echo "no '  - packages/…' entries under 'workspace:' — cannot place the new member" >&2; exit 1
}
grep -qE '^  (shared|feature_[a-z0-9_]+):' pubspec.yaml || {
  echo "no workspace member dependency found in pubspec.yaml — cannot place '$PKG:'" >&2; exit 1
}
grep -q 'externalPackageModulesBefore: \[' "$LOCATOR" || {
  echo "$LOCATOR has no 'externalPackageModulesBefore: [' — cannot register $MODULE" >&2; exit 1
}
grep -qE '^    ExternalModule\(' "$LOCATOR" || {
  echo "$LOCATOR has no ExternalModule entries — cannot place $MODULE" >&2; exit 1
}

SDK="$(grep -m1 -oE '\^[0-9]+\.[0-9]+\.[0-9]+' pubspec.yaml | tr -d '^')"
[[ -n "$SDK" ]] || { echo "could not read the sdk constraint from pubspec.yaml" >&2; exit 1; }

step()   { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
assert() { grep -qF "$2" "$1" || { echo "FAILED to write '$2' into $1" >&2; exit 1; }; }

# ------------------------------------------------------------------- 1. the package
step "creating packages/$PKG"
mkdir -p "packages/$PKG/lib/di"

cat > "packages/$PKG/pubspec.yaml" <<YAML
name: $PKG
version: 0.0.1
environment:
  sdk: ^$SDK
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  core:
  shared:
YAML

cat > "packages/$PKG/lib/di/${PKG}_module.dart" <<DART
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage()
void $INIT() {}
DART

# No data/, domain/ or presentation/ folders: the styleguide creates a subfolder
# only once a file needs it.

# --------------------------------------------------------------------- 2. wiring
step "wiring into pubspec.yaml and $LOCATOR"

# workspace list: after the last '  - packages/…' line
perl -0777 -i -pe "s{((?:^  - packages/\\S+\\n)+)}{\$1  - packages/$PKG\\n}m" pubspec.yaml
assert pubspec.yaml "  - packages/$PKG"

# app dependency: after the last bare workspace member entry
perl -0777 -i -pe "s{((?:^  (?:core|shared|feature_[a-z0-9_]+):\\n)+)}{\$1  $PKG:\\n}m" pubspec.yaml
assert pubspec.yaml "  $PKG:"

# DI: import of the generated micro-package module, after the last import
perl -0777 -i -pe "s{((?:^import [^\\n]+;\\n)+)}{\$1import 'package:$PKG/di/${PKG}_module.module.dart';\\n}m" "$LOCATOR"
assert "$LOCATOR" "import 'package:$PKG/di/${PKG}_module.module.dart';"

# DI: registration, after the last ExternalModule entry
perl -0777 -i -pe "s{((?:^    ExternalModule\\([^\\n]+\\n)+)}{\$1    ExternalModule($MODULE),\\n}m" "$LOCATOR"
assert "$LOCATOR" "ExternalModule($MODULE),"

# ----------------------------------------------------------------- 3. dependencies
step "adding dependencies"
(cd "packages/$PKG" && fvm flutter pub add flutter_bloc injectable dart_mappable >/dev/null)
(cd "packages/$PKG" && fvm flutter pub add --dev build_runner injectable_generator dart_mappable_builder >/dev/null)

step "pub get"
fvm flutter pub get >/dev/null

# ---------------------------------------------------------------------- 4. codegen
# The new member first: the app's DI config imports its generated module.
step "build_runner in packages/$PKG"
(cd "packages/$PKG" && fvm dart run build_runner build)

step "build_runner in the app package"
fvm dart run build_runner build

step "sorting imports"
fvm dart fix --apply --code=directives_ordering >/dev/null

# ----------------------------------------------------------------------- 5. verify
step "flutter analyze"
fvm flutter analyze

printf '\n\033[1;32mDone.\033[0m packages/%s created and registered as %s\n' "$PKG" "$MODULE"
echo "Layers: create packages/$PKG/lib/{data,domain,presentation}/ as files need them."
