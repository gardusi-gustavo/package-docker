# 🐳 Shared images

Canonical source: `templates/docker`. Images are built from that repository
and published to Docker Hub. Gitea packages are not used for images.

## Registry

```text
docker.io/gardusi-gustavo/<name>:<version>
```

The current version is `1`.

## Images

| Image | Purpose |
| --- | --- |
| `ci` | shellcheck, hadolint, and the shared CI entrypoints (source: `templates/docker/infra/docker/ci-tools.dockerfile`) |
| `python` | Python 3 + yamllint |
| `node` | Node/npm + markdownlint |
| `go` | Go toolchain |
| `rust` | Rust/cargo |
| `cpp` | gcc/g++/make/cmake/clang-format |
| `java` | OpenJDK 21 / Maven / Gradle |
| `media` | ffmpeg + imagemagick |

## Build

```bash
cd ~/repos/templates/docker
./infra/scripts/build-images.sh
./infra/scripts/build-images.sh --push
```

`--push` requires a logged-in Docker client for Docker Hub. The `images`
workflow in `dashboards/devops` checks out `templates/docker` and uses the
`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets. The script builds `ci` first
so consumer CI images can use it.

## Image metadata

`infra/scripts/image-metadata.sh` checks or removes embedded metadata from
tracked raster images.

```bash
# Report EXIF, XMP, IPTC, ICC, and comments.
./infra/scripts/image-metadata.sh --check path/to/repo

# Re-encode files that contain metadata.
./infra/scripts/image-metadata.sh --strip path/to/repo
```

- `--check` exits non-zero when metadata is found.
- `--strip` rewrites JPEG and PNG in place, preserving dimensions; it re-encodes
  the pixels and therefore changes the file bytes.
- Container defaults such as JFIF and sRGB are ignored.
- PDFs and images embedded in PDFs are out of scope.
- The script needs Pillow (`python3-pil`).

Run it on the narrowest path needed. Do not bulk-rewrite historical records
without deciding which files are evidence and which are presentational assets.

## Consumer CI

Consumer `infra/docker/ci.dockerfile` files pull the shared tools:

```dockerfile
FROM docker.io/gardusi-gustavo/ci:1 AS ci-tools
```

The image provides `/usr/local/bin/ci`, `ci-lint`, `shellcheck`, and
`hadolint`. Each repository copies only its own `infra/scripts/ci.sh` as
`ci-repo`.
