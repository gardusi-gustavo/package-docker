#!/usr/bin/env bash
set -euo pipefail
ROOT="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
cd "$ROOT"
"$ROOT/infra/scripts/ci/validate-repo.sh" --root "$ROOT"
"$ROOT/infra/scripts/ci/check-size.sh" --root "$ROOT"
for f in infra/docker/*.dockerfile; do
  [[ -s "$f" ]] || { echo "empty $f" >&2; exit 1; }
  grep -qE '^FROM ' "$f" || { echo "$f has no FROM" >&2; exit 1; }
done
for f in infra/scripts/*.sh infra/scripts/runtime/*.sh; do bash -n "$f"; done
echo "docker checks ok"
