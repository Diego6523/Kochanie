#!/usr/bin/env bash
# Runs the business-rule unit tests on the host with Node >= 22 (no device needed).
# rules.ets / models.ets are plain-TS-compatible ArkTS, so we copy them to .ts,
# fix the import paths, and run node:test with built-in type stripping.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
SRC="$ROOT/entry/src/main/ets/common"
cp "$SRC/models.ets" "$OUT/models.ts"
sed -e "s#^import { \(.*\) } from './models';#import type { \1 } from './models.ts';#" \
  "$SRC/rules.ets" > "$OUT/rules.ts"
cp "$ROOT/tests/rules.test.ts" "$OUT/rules.test.ts"
node --experimental-strip-types --no-warnings --test "$OUT/rules.test.ts"
