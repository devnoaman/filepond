#!/usr/bin/env bash
# Full local check for the filepond package and the Upload Lab example:
# codegen → analyze → tests (+ coverage). Usage: tool/check.sh [--no-codegen]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

step() { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }

cd "$ROOT/packages/filepond"
step "filepond: pub get"
flutter pub get

if [[ "${1:-}" != "--no-codegen" ]]; then
  step "filepond: build_runner (freezed / json_serializable)"
  dart run build_runner build --delete-conflicting-outputs
fi

step "filepond: analyze"
flutter analyze

step "filepond: tests + coverage"
flutter test --coverage
if command -v lcov >/dev/null 2>&1; then
  lcov --summary coverage/lcov.info 2>/dev/null | tail -n 3 || true
fi

cd "$ROOT/apps/example"
step "example (Upload Lab): pub get + analyze + tests"
flutter pub get
flutter analyze
flutter test

printf '\n\033[1;32m✔ all checks passed\033[0m\n'
