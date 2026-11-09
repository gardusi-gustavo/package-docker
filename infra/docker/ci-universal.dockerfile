# syntax=docker/dockerfile:1
# Universal CI image for Gitea jobs. Built by the runner, not by PR code.
FROM docker.io/kapetim/ci:1 AS ci-tools
FROM golang:1.23-bookworm AS go-tools
FROM node:22-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git jq python3 python3-pip build-essential curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
  | sh -s -- -y --default-toolchain 1.85.0 --profile minimal

RUN python3 -m pip install --break-system-packages --no-cache-dir ruff pytest

COPY --from=go-tools /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH

COPY --from=ci-tools /usr/local/bin/ci /usr/local/bin/ci
COPY --from=ci-tools /usr/local/bin/ci-lint /usr/local/bin/ci-lint
COPY --from=ci-tools /usr/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=ci-tools /usr/local/bin/hadolint /usr/local/bin/hadolint
RUN chmod +x /usr/local/bin/ci /usr/local/bin/ci-lint

WORKDIR /workspace
