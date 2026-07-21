#!/bin/sh
set -eu

IMAGE_NAME="${IMAGE_NAME:-esphome-armv7}"
ESPHOME_VERSION="${ESPHOME_VERSION:-2026.7.1}"
UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY:-https://github.com/esphome/esphome.git}"
BUILD_DIR="${BUILD_DIR:-.build/esphome-${ESPHOME_VERSION}}"

rm -rf "${BUILD_DIR}"
mkdir -p "$(dirname "${BUILD_DIR}")"

git clone --depth 1 --branch "${ESPHOME_VERSION}" \
  "${UPSTREAM_REPOSITORY}" "${BUILD_DIR}"
cp Dockerfile "${BUILD_DIR}/docker/Dockerfile.armv7"

docker build \
  --tag "${IMAGE_NAME}:${ESPHOME_VERSION}" \
  --build-arg BUILD_VERSION="${ESPHOME_VERSION}" \
  --file "${BUILD_DIR}/docker/Dockerfile.armv7" \
  "${BUILD_DIR}"
