#!/usr/bin/env bash
set -euo pipefail

out="${1:-}"
if [ -z "$out" ]; then
  echo "usage: $0 <output-json>" >&2
  exit 1
fi

jq -n \
  --arg repository "${UPSTREAM_REPO:?UPSTREAM_REPO is required}" \
  --arg tag "${UPSTREAM_TAG:?UPSTREAM_TAG is required}" \
  --arg commit "${UPSTREAM_COMMIT:?UPSTREAM_COMMIT is required}" \
  --arg buildDate "${BUILD_DATE:?BUILD_DATE is required}" \
  --arg goVersion "$(go version)" \
  '{repository: $repository, tag: $tag, commit: $commit, buildDate: $buildDate, goVersion: $goVersion}' \
  > "$out"
