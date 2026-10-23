#!/usr/bin/env bash
set -euo pipefail
node tool/verify_edge_runtime.mjs

# Build outside iCloud-managed Desktop folders and validate before replacing dist.
pact_web_output=$(mktemp -d "${TMPDIR:-/tmp}/pact-web-build.XXXXXX")
pact_dist_stage=''
cleanup() {
  rm -rf "$pact_web_output"
  if [[ -n "$pact_dist_stage" && -d "$pact_dist_stage" ]]; then
    rm -rf "$pact_dist_stage"
  fi
}
trap cleanup EXIT

if [[ -f .env.flutter.json ]]; then
  flutter build web --release --no-wasm-dry-run --output="$pact_web_output" --dart-define-from-file=.env.flutter.json
else
  flutter build web --release --no-wasm-dry-run --output="$pact_web_output"
fi
for pact_bundle_file in index.html flutter_bootstrap.js main.dart.js; do
  if [[ ! -s "$pact_web_output/$pact_bundle_file" ]]; then
    echo "Incomplete web build: $pact_bundle_file is missing; existing dist preserved." >&2
    exit 1
  fi
done
node tool/verify_edge_runtime.mjs "$pact_web_output"
pact_dist_stage=$(mktemp -d ./.pact-dist-stage.XXXXXX)
cp -R "$pact_web_output/." "$pact_dist_stage/"
pact_previous=$(mktemp -d ./.pact-dist-previous.XXXXXX)
if [[ -d dist ]]; then mv dist "$pact_previous/dist"; fi
if mv "$pact_dist_stage" dist; then
  rm -rf "$pact_previous"
else
  if [[ -d "$pact_previous/dist" ]]; then mv "$pact_previous/dist" dist; fi
  rmdir "$pact_previous"
  exit 1
fi
node tool/verify_prebuilt.mjs
