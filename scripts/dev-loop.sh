#!/usr/bin/env bash
# lint -> build -> install -> launch, stopping at the first failure.
set -euo pipefail
cd "$(dirname "$0")/.."
oniro-app lint
oniro-app build 2>&1 | grep -E 'ERROR|WARN|BUILD|error:' || true
test -f entry/build/default/outputs/default/entry-default-signed.hap
oniro-app app install | tail -1
oniro-app app launch | tail -1
