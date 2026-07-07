FROM alpine:latest

RUN apk add --no-cache \
    git \
    openssh-client \
    bash \
    curl \
    ca-certificates

RUN mkdir -p /xgit-home/runtime

VOLUME ["/repo", "/xgit-home"]
WORKDIR /repo

ENV HOME=/xgit-home/runtime
ENV GIT_CONFIG_NOSYSTEM=1

ENTRYPOINT ["/usr/bin/env"]
