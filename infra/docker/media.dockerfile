# media runtime image — workflows:${version}-media.
# The media ecosystem: ffmpeg (video) + imagemagick (image).

FROM alpine:3.21 AS src
WORKDIR /src
COPY . .

FROM alpine:3.21 AS final

COPY --from=src /src/infra/scripts/runtime /install/
RUN apk add --no-cache bash \
    && bash /install/install-core.sh \
    && bash /install/install-media.sh
