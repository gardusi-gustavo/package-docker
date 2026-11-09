#!/usr/bin/env bash
# Build shared images and publish them to Docker Hub.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

registry="${IMAGE_REGISTRY:-docker.io/gardusi-gustavo}"
version="1"
push=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || { echo "error: --version needs a value" >&2; exit 2; }
      version="$2"
      shift 2
      ;;
    --push)
      push=1
      shift
      ;;
    -h|--help)
      echo "usage: build-images.sh [--version N] [--push]"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

images=(ci python node go rust cpp java media)

for name in "${images[@]}"; do
  case "$name" in
    ci) dockerfile="infra/docker/ci-tools.dockerfile" ;;
    *)  dockerfile="infra/docker/${name}.dockerfile" ;;
  esac
  [[ -s "$dockerfile" ]] || { echo "missing $dockerfile" >&2; exit 1; }
  image="${registry}/${name}:${version}"
  echo "building $image from $dockerfile"
  docker build -f "$dockerfile" -t "$image" .
  if ((push)); then
    docker push "$image"
  fi
done

echo "built ${#images[@]} image(s) for ${registry}/*:${version}"
