#!/usr/bin/env bash
set -euo pipefail

ROOTFS="${1:?Usage: build/install-package.sh <rootfs> <pkg-tar.gz>}"
PKG_TARBALL="${2:?Usage: build/install-package.sh <rootfs> <pkg-tar.gz>}"
PKG_DB_DIR="$ROOTFS/var/lib/alloy-pkgs"

mkdir -p "$ROOTFS" "$PKG_DB_DIR"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Extracting $PKG_TARBALL into $ROOTFS"
tar -xzf "$PKG_TARBALL" -C "$tmpdir"
sudo rsync -aH --numeric-ids "$tmpdir"/ "$ROOTFS"/

# Record installed package
pkgname=$(basename "$PKG_TARBALL")
echo "${pkgname} | $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PKG_DB_DIR/installed.txt"

echo "Installed: $pkgname"
echo "Note: Rust equivalent is available via tools/alloy-pkg"
