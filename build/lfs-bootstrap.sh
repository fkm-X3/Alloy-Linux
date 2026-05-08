#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="${1:-$REPO_ROOT/build/output}"
ROOTFS_DIR="${ROOTFS_DIR:-$OUT_DIR/rootfs}"
LFS_LOG_DIR="${LFS_LOG_DIR:-$OUT_DIR/logs}"
STAGE="${STAGE:-all}"

mkdir -p "$OUT_DIR" "$LFS_LOG_DIR"

log() {
  local msg="$1"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $msg" | tee -a "$LFS_LOG_DIR/lfs-bootstrap.log"
}

stage_cross_toolchain() {
  log "Stage 1: cross-toolchain bootstrap metadata"
  mkdir -p "$OUT_DIR/toolchain"
  cat > "$OUT_DIR/toolchain/README" <<'EOF'
This directory is reserved for LFS cross-toolchain artifacts.
Use scripts/toolchain/setup-toolchain.sh to validate host tooling.
EOF
}

stage_temp_tools() {
  log "Stage 2: temporary tools skeleton"
  mkdir -p "$OUT_DIR/temp-tools"/{bin,lib,include}
}

stage_target_rootfs() {
  log "Stage 3: rootfs baseline layout"
  "$SCRIPT_DIR/mkrootfs.sh" "$ROOTFS_DIR"
  mkdir -p "$ROOTFS_DIR/etc/alloy"
  cp "$REPO_ROOT/meta/versions.yaml" "$ROOTFS_DIR/etc/alloy/versions.yaml"
}

case "$STAGE" in
  stage1)
    stage_cross_toolchain
    ;;
  stage2)
    stage_temp_tools
    ;;
  stage3)
    stage_target_rootfs
    ;;
  all)
    stage_cross_toolchain
    stage_temp_tools
    stage_target_rootfs
    ;;
  *)
    echo "Invalid STAGE: $STAGE (expected stage1|stage2|stage3|all)"
    exit 1
    ;;
esac

log "LFS bootstrap scaffold complete"
