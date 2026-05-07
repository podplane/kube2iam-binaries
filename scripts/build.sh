#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
OUT_DIR="${2:-dist}"

UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/jtblin/kube2iam.git}"
PUBLISH="${PUBLISH:-false}"

if [ -z "$TAG" ]; then
  echo "usage: $0 <tag> [out_dir]" >&2
  exit 1
fi

log() { printf '[build] %s\n' "$*"; }
fatal() { printf '[build] FATAL: %s\n' "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || fatal "required tool missing: $1"
}

require git
require go
require goreleaser
require jq

resolve_tag_commit() {
  local line ref_sha deref_sha
  line="$(git ls-remote --tags "$UPSTREAM_REPO" "refs/tags/${TAG}" | awk 'NR == 1 {print $1}')"
  [ -n "$line" ] || fatal "upstream tag not found: $TAG"
  ref_sha="$line"
  # Annotated tags have a peeled ^{} ref. Lightweight tags do not.
  deref_sha="$(git ls-remote --tags "$UPSTREAM_REPO" "refs/tags/${TAG}^{}" | awk 'NR == 1 {print $1}')"
  if [ -n "$deref_sha" ]; then
    printf '%s' "$deref_sha"
  else
    printf '%s' "$ref_sha"
  fi
}

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

COMMIT_SHA="${UPSTREAM_COMMIT_SHA:-$(resolve_tag_commit)}"
SHORT_SHA="${COMMIT_SHA:0:12}"
SRC_DIR="$WORK_DIR/src"
MIRROR_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_PATH="$MIRROR_ROOT/.goreleaser.yaml"

log "checking out ${UPSTREAM_REPO} tag ${TAG} at ${COMMIT_SHA}"
git clone --quiet --filter=blob:none --no-checkout "$UPSTREAM_REPO" "$SRC_DIR"
git -C "$SRC_DIR" fetch --quiet --depth=1 origin "refs/tags/${TAG}:refs/tags/${TAG}"
git -C "$SRC_DIR" checkout --quiet --detach "refs/tags/${TAG}"

# Record the commit time as build metadata rather than wall-clock time. This
# keeps rebuilds stable while still preserving useful `kube2iam --version` data.
BUILD_DATE="$(git -C "$SRC_DIR" show -s --format=%cI "$COMMIT_SHA")"
SOURCE_JSON="$SRC_DIR/kube2iam_${TAG}_source.json"

log "running GoReleaser"
goreleaser_args=(release --clean --config "$CONFIG_PATH")
if [ "$PUBLISH" != "true" ] && [ "$PUBLISH" != "1" ]; then
  goreleaser_args+=(--skip=publish --skip=sign)
fi
(
  cd "$SRC_DIR"
  BUILD_DATE="$BUILD_DATE" \
    MIRROR_ROOT="$MIRROR_ROOT" \
    UPSTREAM_COMMIT="$COMMIT_SHA" \
    UPSTREAM_REPO="$UPSTREAM_REPO" \
    UPSTREAM_SHORT_COMMIT="$SHORT_SHA" \
    UPSTREAM_TAG="$TAG" \
    goreleaser "${goreleaser_args[@]}"
)

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
find "$SRC_DIR/dist" -maxdepth 1 -type f -name 'kube2iam_*' -exec cp {} "$OUT_DIR"/ \;
cp "$SOURCE_JSON" "$OUT_DIR"/

log "done"
