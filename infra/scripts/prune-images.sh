#!/usr/bin/env bash
# Remove unused Docker images older than seven days, keeping the runner images.
set -euo pipefail

MODE="list"
SCOPE="rootless"
for arg in "$@"; do
  case "$arg" in
    --list) MODE="list" ;;
    --apply) MODE="apply" ;;
    --rootless) SCOPE="rootless" ;;
    --rootful) SCOPE="rootful" ;;
    -h|--help)
      echo "usage: prune-images.sh [--list|--apply] [--rootless|--rootful]"
      exit 0 ;;
    *) echo "error: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [[ "$SCOPE" == "rootless" ]]; then
  [[ "$(id -un)" == "gitea-runner" ]] || {
    echo "error: rootless mode must run as gitea-runner" >&2
    exit 2
  }
  DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"
  export DOCKER_HOST
else
  export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"
fi

KEEP=(
  "gitea/ci-universal:latest"
  "docker.gitea.com/runner-images:ubuntu-latest"
  "gitea/runner:5"
  "alpine:latest"
  "gitea/gitea:28.2.0"
  "python:3.11-slim"
)

is_keep() {
  local name="$1" k
  for k in "${KEEP[@]}"; do
    [[ "$name" == "$k" ]] && return 0
  done
  return 1
}

used_ids="$(docker ps -aq | xargs -r docker inspect --format '{{.Image}}' 2>/dev/null | sort -u || true)"
keep_ids=""
for k in "${KEEP[@]}"; do
  id="$(docker image inspect --format '{{.Id}}' "$k" 2>/dev/null || true)"
  [[ -n "$id" ]] && keep_ids+="$id"$'\n'
done
now="$(date +%s)"
cutoff=$((now - 7*24*3600))
candidates=()

while IFS=$'\t' read -r name id created; do
  [[ -n "$id" ]] || continue
  is_keep "$name" && continue
  if grep -qxF "$id" <<<"$used_ids"; then
    continue
  fi
  if grep -qxF "$id" <<<"$keep_ids"; then
    continue
  fi
  created_epoch="$(date -u -d "$created" +%s 2>/dev/null || echo "$now")"
  if (( created_epoch < cutoff )); then
    candidates+=("$id"$'\t'"$name"$'\t'"$created")
  fi
done < <(docker images --no-trunc --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}')

if (( ${#candidates[@]} == 0 )); then
  echo "no unused images older than 7 days"
else
  printf 'candidate\t%s\n' "${candidates[@]}"
fi

if [[ "$MODE" == "apply" ]]; then
  for row in "${candidates[@]}"; do
    id="${row%%$'\t'*}"
    docker rmi -f "$id" >/dev/null
    echo "removed ${row#*$'\t'}"
  done
  docker builder prune -f --filter "until=168h"
  docker container prune -f
  echo "docker prune complete ($SCOPE)"
else
  echo "list only; rerun with --apply to remove"
fi
