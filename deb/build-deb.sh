#!/bin/sh
# Build the k9s Debian package inside the container.
#
# Expects (see deb/docker-compose.yml):
#   /src   read-only mount of the repository
#   /work  scratch space for the package build
#   /out   writable output directory, bound to deb/dist/ on the host
set -eu

SRC_DIR="${SRC_DIR:-/src}"
WORK_DIR="${WORK_DIR:-/work}"
OUT_DIR="${OUT_DIR:-/out}"

echo "==> Copying source into ${WORK_DIR}/k9s (host tree stays pristine)"
rm -rf "${WORK_DIR}/k9s"
mkdir -p "${WORK_DIR}/k9s"
cp -a "${SRC_DIR}/." "${WORK_DIR}/k9s/"
cd "${WORK_DIR}/k9s"

echo "==> Vendoring Go module dependencies (go mod vendor)"
go mod vendor

echo "==> Building binary-only Debian package (dpkg-buildpackage -b -us -uc)"
dpkg-buildpackage -b -us -uc

echo "==> Build artifacts:"
ls -lh "${WORK_DIR}"/k9s_*

echo "==> Checking with lintian (--fail-on error)"
lintian --info --fail-on error "${WORK_DIR}"/k9s_*.changes

mkdir -p "${OUT_DIR}"
cp "${WORK_DIR}"/k9s_*.deb "${WORK_DIR}"/k9s_*.buildinfo "${WORK_DIR}"/k9s_*.changes "${OUT_DIR}/"

echo "==> Copied to ${OUT_DIR}:"
ls -lh "${OUT_DIR}"
