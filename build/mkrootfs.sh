#!/usr/bin/env bash
set -euo pipefail
ROOTFS_DIR="${1:-./rootfs}"
mkdir -p "$ROOTFS_DIR"/{bin,boot,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
mkdir -p "$ROOTFS_DIR"/usr/{bin,sbin,lib,share}
mkdir -p "$ROOTFS_DIR"/var/{lib,log,tmp}
chmod 1777 "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/var/tmp"
echo "Created minimal rootfs at $ROOTFS_DIR"
