# syntax=docker/dockerfile:1
FROM docker.io/gardusi-gustavo/ci:1 AS ci-tools
FROM golang:1.24-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends git jq \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ci-tools \
     /usr/local/bin/ci /usr/local/bin/ci
COPY --from=ci-tools \
     /usr/local/bin/ci-lint /usr/local/bin/ci-lint
COPY --from=ci-tools \
     /usr/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=ci-tools \
     /usr/local/bin/hadolint /usr/local/bin/hadolint

COPY infra/scripts/ci.sh /usr/local/bin/ci-repo
RUN chmod +x /usr/local/bin/ci /usr/local/bin/ci-lint /usr/local/bin/ci-repo

WORKDIR /repo
ENTRYPOINT ["/usr/local/bin/ci"]
