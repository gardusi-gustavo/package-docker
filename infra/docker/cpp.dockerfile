# cpp runtime image — workflows:${version}-cpp.
# The C/C++ ecosystem: gcc/g++/make/cmake/clang-format.

FROM alpine:3.21 AS src
WORKDIR /src
COPY . .

FROM alpine:3.21 AS final

COPY --from=src /src/infra/scripts/runtime /install/
RUN apk add --no-cache bash \
    && bash /install/install-core.sh \
    && bash /install/install-cpp.sh
