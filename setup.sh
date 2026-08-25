#!/usr/bin/env bash
# Scaffolds a new Flutter workspace project from template/.
# Order matters: `flutter create` must run BEFORE `fvm use`, otherwise fvm
# pre-creates a .gitignore and create skips writing the Flutter one.
set -euo pipefail

# Repo that hosts template/. Change this one line when you fork.
REPO="${FLUTTER_TEMPLATE_REPO:-CHANGE-ME/flutter-workspace}"
REF="main"

NAME=""
ORG=""
TITLE=""
PLATFORMS="android,ios"
FLUTTER="stable"
LOG_GIT_URL=""
LOG_GIT_REF=""
TARGET="."

usage() {
  cat <<'USAGE'
Usage: ./setup.sh --name <app_name> --org <com.example> [options]

  --name <app_name>       Dart package name, snake_case (required)
  --org <com.example>     reverse-DNS org for bundle ids (required)
  --title <"My App">      human-readable title (default: derived from --name)
  --platforms <list>      flutter create --platforms (default: android,ios)
  --flutter <version>     FVM Flutter version (default: stable)
  --log-git-url <url>     git url of the klog package (optional)
  --log-git-ref <ref>     tag or commit for `log` (optional)
  --target <dir>          target directory (default: current directory)
  --ref <branch|tag>      template revision to fetch (default: main)

Run from a checkout, or straight from the web:
  curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/setup.sh \
    | bash -s -- --name my_app --org com.example --target ~/Code/my_app
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --org) ORG="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --platforms) PLATFORMS="$2"; shift 2 ;;
    --flutter) FLUTTER="$2"; shift 2 ;;
    --log-git-url) LOG_GIT_URL="$2"; shift 2 ;;
    --log-git-ref) LOG_GIT_REF="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$NAME" && -n "$ORG" ]] || { usage; exit 1; }
[[ "$NAME" =~ ^[a-z][a-z0-9_]*$ ]] || {
  echo "--name must be snake_case and start with a letter: '$NAME'" >&2; exit 1
}
command -v fvm >/dev/null || { echo "fvm not on PATH" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl not on PATH" >&2; exit 1; }

# Prefer a template/ next to this script; otherwise fetch the repo tarball.
# When piped through `curl | bash` there is no script path, so this always
# falls through to the download.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo .)"
if [[ -d "$SELF_DIR/template" ]]; then
  TEMPLATE_DIR="$SELF_DIR/template"
  echo "using local template: $TEMPLATE_DIR"
else
  TARBALL="${FLUTTER_TEMPLATE_URL:-https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF}"
  FETCH_DIR="$(mktemp -d)"
  trap 'rm -rf "$FETCH_DIR"' EXIT
  echo "fetching template: $TARBALL"
  curl -fsSL "$TARBALL" | tar -xz -C "$FETCH_DIR" --strip-components=1
  TEMPLATE_DIR="$FETCH_DIR/template"
  [[ -d "$TEMPLATE_DIR" ]] || {
    echo "downloaded archive has no template/ directory" >&2; exit 1
  }
fi
[[ -n "$TITLE" ]] || TITLE="$(echo "$NAME" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
if [[ -n "$(ls -A "$TARGET")" ]]; then
  echo "target '$TARGET' is not empty — refusing to scaffold" >&2
  exit 1
fi

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------- 1. create
# `fvm spawn <version>` — NOT `fvm flutter` — is load-bearing here. No .fvmrc
# exists yet at this point, and `fvm flutter` would fall back to whatever
# `flutter` is on PATH: silently the wrong version, or nothing at all. The
# create step writes version-dependent artifacts (.metadata revision, AGP,
# Kotlin and Gradle wrapper versions, Podfile) that `fvm use` does NOT
# retro-fix, so the project must be created by the target SDK from the start.
step "flutter create ($FLUTTER, platforms: $PLATFORMS)"
cd "$TARGET"
fvm spawn "$FLUTTER" create \
  --org "$ORG" \
  --project-name "$NAME" \
  --platforms="$PLATFORMS" \
  --no-pub \
  .

# ------------------------------------------------------------------ 2. fvm use
# Must come after create so fvm appends to the Flutter .gitignore.
step "fvm use $FLUTTER"
fvm use "$FLUTTER" --force

grep -qE '^/?build/$' .gitignore && grep -qE '^\.dart_tool/$' .gitignore &&
  grep -qE '^\.fvm/$' .gitignore || {
  echo "ERROR: .gitignore incomplete — 'flutter create' must run before 'fvm use'" >&2
  exit 1
}

SDK="$(fvm dart --version 2>&1 | sed -n 's/.*Dart SDK version: \([0-9.]*\).*/\1/p')"
[[ -n "$SDK" ]] || { echo "could not determine Dart SDK version" >&2; exit 1; }
echo "Dart SDK: $SDK"

# ------------------------------------------------------------- 3. copy template
step "copying template"
rm -f lib/main.dart analysis_options.yaml
rm -rf test  # the styleguide does not use tests
cp -R "$TEMPLATE_DIR"/. .

# ------------------------------------------------------------ 4. substitute
step "substituting placeholders"
FILES=$(grep -rl '__APP_NAME__\|__APP_TITLE__\|__SDK__' . \
  --include='*.dart' --include='*.yaml' --include='*.arb' --include='*.md' || true)
for file in $FILES; do
  APP_NAME="$NAME" APP_TITLE="$TITLE" SDK_V="$SDK" perl -pi -e \
    's/__APP_NAME__/$ENV{APP_NAME}/g;
     s/__APP_TITLE__/$ENV{APP_TITLE}/g;
     s/__SDK__/$ENV{SDK_V}/g' "$file"
done

# --------------------------------------------------------------- 5. pub add
# No version numbers live in the template: pub add writes current constraints.
step "adding dependencies"
add()     { (cd "$1" && shift && fvm flutter pub add "$@" >/dev/null); }
add_dev() { (cd "$1" && shift && fvm flutter pub add --dev "$@" >/dev/null); }

add . flutter_bloc get_it go_router injectable intl
(cd . && fvm flutter pub add flutter_localizations --sdk=flutter >/dev/null)
add_dev . build_runner flutter_lints injectable_generator
if [[ -n "$LOG_GIT_URL" ]]; then
  REF_ARG=()
  [[ -n "$LOG_GIT_REF" ]] && REF_ARG=(--git-ref="$LOG_GIT_REF")
  add . klog --git-url="$LOG_GIT_URL" "${REF_ARG[@]}"
else
  echo "  (skipping 'klog' — pass --log-git-url to include it)"
fi

add packages/core dio injectable dart_mappable
add_dev packages/core build_runner injectable_generator

add packages/shared go_router intl injectable dart_mappable
add_dev packages/shared build_runner dart_mappable_builder injectable_generator

add packages/feature_home dio flutter_bloc injectable dart_mappable
add_dev packages/feature_home build_runner dart_mappable_builder injectable_generator

# ------------------------------------------------------------------ 6. codegen
step "pub get"
fvm flutter pub get

step "gen-l10n"
(cd packages/shared && fvm flutter gen-l10n)

# Member packages first: the app package's DI config imports their generated
# micro-package modules.
step "build_runner"
for package in packages/* .; do
  grep -q 'build_runner' "$package/pubspec.yaml" || continue
  echo "  $package"
  (cd "$package" && fvm dart run build_runner build)
done

# --------------------------------------------------------------- 7. sort imports
# `package:<app>/...` sorts differently for every project name, so the template
# cannot ship a statically correct order.
step "sorting imports"
fvm dart fix --apply --code=directives_ordering >/dev/null

# ------------------------------------------------------------------ 8. verify
step "flutter analyze"
fvm flutter analyze

printf '\n\033[1;32mDone.\033[0m %s scaffolded in %s\n' "$NAME" "$TARGET"
echo "Next: fvm flutter run"
