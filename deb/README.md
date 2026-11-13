# Building the k9s Debian package

This directory holds a containerized build environment so no packages ever
need to be installed on the host. The Debian packaging itself lives in
[`debian/`](../debian/) at the repository root, where `dpkg-buildpackage`
expects it.

## Usage

```sh
docker compose -f deb/docker-compose.yml run --rm deb
```

The first run builds the image and downloads Go modules, so it takes a few
minutes; later runs are faster thanks to the persistent `go-cache` volume.
Artifacts end up in `deb/dist/`:

```
k9s_0.51.0-1_amd64.deb
k9s_0.51.0-1_amd64.buildinfo
k9s_0.51.0-1_amd64.changes
```

Try the result with dpkg, still without touching the host:

```sh
docker run --rm -it -v "$PWD/deb/dist":/dist debian:trixie \
    sh -c "dpkg -i /dist/k9s_*.deb && k9s version"
```

## Layout

| File | Purpose |
| --- | --- |
| `Dockerfile` | Build environment: trixie, packaging tools, pinned Go 1.26.8 (sha256-verified against the official download index). Runs as a non-root `builder` user. |
| `Dockerfile.dockerignore` | Used by BuildKit instead of the repo-root `.dockerignore`; excludes `.git`, docs, screenshots, etc. from the build context. |
| `docker-compose.yml` | Mounts the repo read-only at `/src`, `deb/dist/` at `/out`, and a named `go-cache` volume at `/go`. |
| `build-deb.sh` | Copies the source to `/work`, vendors Go modules, runs `dpkg-buildpackage -b -us -uc`, checks the result with lintian, and copies artifacts to `/out`. |

## Notes on the packaging

- Source format is `3.0 (quilt)`; the `.deb` is built binary-only (`-b`), so
  no upstream tarball is needed.
- `go mod vendor` runs before `dpkg-buildpackage`, so the package build
  itself is offline and reproducible; `debian/rules` builds with
  `-mod=vendor -trimpath` and injects version metadata from
  `debian/changelog` plus `SOURCE_DATE_EPOCH`.
- The image installs both trixie's `golang-go` (matching the declared
  `Build-Depends`) and the pinned upstream Go required by `go.mod`
  (1.26.8 > trixie's 1.24.x). Either toolchain can drive the build.
- The package installs the binary plus bash/zsh/fish completions and a
  help2man man page; an autopkgtest smoke test lives in
  `debian/tests/control`.

## Bumping the version

1. `deb/docker-compose.yml` — nothing to change (version comes from the changelog).
2. Add an entry at the top of `debian/changelog` (e.g. with `dch -v 0.52.0-1`
   inside the container).
