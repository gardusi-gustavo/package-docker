#!/usr/bin/env bash
# Build the universal CI image in gitea-runner's rootless Docker.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
IMAGE="${CI_UNIVERSAL_IMAGE:-gitea/ci-universal:latest}"
DOCKERFILE="$ROOT/infra/docker/ci-universal.dockerfile"

[[ "$(id -un)" == "gitea-runner" ]] || { echo "error: run as gitea-runner" >&2; exit 2; }
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"
command -v docker >/dev/null || { echo "error: docker is required" >&2; exit 2; }
[[ -r "$DOCKERFILE" ]] || { echo "error: missing $DOCKERFILE" >&2; exit 2; }

docker build -f "$DOCKERFILE" -t "$IMAGE" "$ROOT"
docker run --rm "$IMAGE" sh -c 'node --version; cargo --version; python3 --version; jq --version'
echo "built $IMAGE"
