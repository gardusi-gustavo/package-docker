# rust runtime image — workflows:${version}-rust.
# The Rust ecosystem: rust/cargo toolchain.

FROM alpine:3.21 AS src
WORKDIR /src
COPY . .

FROM alpine:3.21 AS final

COPY --from=src /src/infra/scripts/runtime /install/
RUN apk add --no-cache bash \
    && bash /install/install-core.sh \
    && bash /install/install-rust.sh
