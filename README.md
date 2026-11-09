# package-docker

Dockerfiles, CI images, runtime installers, and image build helpers.

## Layout

| Path | Holds |
| --- | --- |
| `infra/docker/` | base, universal, language, and media images |
| `infra/scripts/runtime/` | language/runtime installers |
| `infra/scripts/build-images.sh` | build and optionally push the image set |
| `docs/images.md` | image catalog and upgrade policy |

## Build

```bash
bash infra/scripts/ci.sh
# with Docker:
bash infra/scripts/build-images.sh --version 1
```
