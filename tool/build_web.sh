#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env.flutter.json ]]; then
  flutter build web --release --no-wasm-dry-run --dart-define-from-file=.env.flutter.json
else
  flutter build web --release --no-wasm-dry-run
fi

rm -rf dist
cp -R build/web dist
echo "Flutter web build copied to dist/."
