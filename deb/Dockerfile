# Build environment for the k9s Debian package (Debian 13 "trixie").
#
# Nothing here installs anything on the host: this image is only used
# through deb/docker-compose.yml:
#
#   docker compose -f deb/docker-compose.yml run --rm deb
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

# Packaging tools (debhelper, lintian, help2man, dpkg-dev via
# build-essential) plus curl/jq for fetching and verifying the Go
# toolchain below.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        debhelper \
        git \
        golang-go \
        help2man \
        jq \
        lintian \
    && rm -rf /var/lib/apt/lists/*

# k9s' go.mod requires Go >= 1.26.8, which is newer than trixie's
# golang-go. Install the pinned upstream toolchain as the primary one,
# verifying its sha256 against the official download index. The distro
# golang-go stays installed as a fallback: with GOTOOLCHAIN=auto (the
# default) it can fetch the required toolchain by itself.
ARG GO_VERSION=1.26.8
ARG TARGETARCH
RUN set -eu; \
    curl -fsSL "https://go.dev/dl/?mode=json&include=all" -o /tmp/go-index.json; \
    sha="$(jq -er --arg file "go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
        '[.[] | .files[] | select(.filename == $file) | .sha256][0]' /tmp/go-index.json)"; \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" -o /tmp/go.tgz; \
    echo "${sha}  /tmp/go.tgz" | sha256sum -c -; \
    tar -C /usr/local -xzf /tmp/go.tgz; \
    rm -f /tmp/go.tgz /tmp/go-index.json

# Go caches live under /go, which docker-compose.yml mounts as a named
# volume so rebuilds are fast.
ENV PATH="/usr/local/go/bin:${PATH}" \
    GOPATH=/go \
    GOCACHE=/go/cache \
    GOMODCACHE=/go/mod \
    CGO_ENABLED=0

# Run as a regular user so artifacts written to /out are owned by the
# host user. dpkg-buildpackage does not need root because the package
# declares Rules-Requires-Root: no.
ARG UID=1000
ARG GID=1000
RUN groupadd --gid "${GID}" builder \
    && useradd --uid "${UID}" --gid "${GID}" --create-home builder \
    && mkdir -p /go /work /out \
    && chown -R builder:builder /go /work /out

USER builder

COPY --chown=builder:builder deb/build-deb.sh /usr/local/bin/build-deb.sh

CMD ["build-deb.sh"]
