# syntax=docker/dockerfile:1
# Shared CI tooling image for every repository.
# Published as docker.io/gardusi-gustavo/ci:<version>.
#
# Repo Dockerfiles copy these files into their own base image:
#   /usr/local/bin/ci        shared entrypoint (lint, then the repo script)
#   /usr/local/bin/ci-lint   common lint suite
#   /usr/bin/shellcheck
#   /usr/local/bin/hadolint

FROM debian:bookworm-slim

ARG HADOLINT_VERSION=2.15.1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git jq make shellcheck \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL \
      "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
      -o /usr/local/bin/hadolint \
 && chmod +x /usr/local/bin/hadolint

COPY infra/scripts/ci-lint.sh /usr/local/bin/ci-lint
COPY infra/scripts/ci-entrypoint.sh /usr/local/bin/ci
RUN chmod +x /usr/local/bin/ci-lint /usr/local/bin/ci

WORKDIR /repo
