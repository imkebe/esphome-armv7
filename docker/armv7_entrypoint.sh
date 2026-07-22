#!/usr/bin/env bash
set -euo pipefail

# ESPHome 2026.7 stores the native ESP-IDF install under the prefix below.
# Older versions (and early ARMv7 image revisions) configured CMake projects
# against the container-local /root cache. That cache disappears on a normal
# container replacement, while the generated CMake cache persists in /config.
# Remove only such stale generated CMake directories before delegating to the
# upstream entrypoint; configuration YAML and PlatformIO packages are untouched.
legacy_idf_prefix=/root/.cache/esphome/idf
build_root=/config/.esphome/build

if [[ -d "${build_root}" ]]; then
  while IFS= read -r -d '' cmake_cache; do
    if grep -Fqs "${legacy_idf_prefix}" "${cmake_cache}"; then
      stale_build_dir=$(dirname "${cmake_cache}")
      echo "Removing stale ESP-IDF build cache: ${stale_build_dir}"
      rm -rf "${stale_build_dir}"
    fi
  done < <(find "${build_root}" -type f -name CMakeCache.txt -print0)
fi

exec /entrypoint.upstream.sh "$@"
