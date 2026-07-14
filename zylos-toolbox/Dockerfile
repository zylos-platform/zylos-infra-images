FROM alpine:3.21

RUN apk add --no-cache curl jq ca-certificates \
    && adduser -D -u 65532 nonroot \

USER 65532:65532
ENTRYPOINT ["/bin/sh"]
