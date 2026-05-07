SHELL := bash

OUTPUT_DIR ?= ./build/output
ROOTFS_DIR ?= $(OUTPUT_DIR)/rootfs
BOOT_DIR ?= $(OUTPUT_DIR)/boot
IMAGE_PATH ?= $(OUTPUT_DIR)/alloy-orangepi5.img
KERNEL_BUILD_DIR ?= $(OUTPUT_DIR)/kernel

.PHONY: help setup build all rust-build rust-test kernel bootstrap rootfs image \
        repro-check qemu-smoke pkg-hello install-hello clean

help:
	@echo "Alloy-Linux common targets"
	@echo "  make setup         Validate cross toolchain and emit env file"
	@echo "  make build         Bootstrap + build Rust workspace"
	@echo "  make kernel        Build ARM64 kernel + boot artifacts"
	@echo "  make rootfs        Create minimal rootfs layout"
	@echo "  make image         Build bootable ext4 image"
	@echo "  make rust-test     Run Rust workspace tests"
	@echo "  make repro-check   Validate reproducibility manifests"
	@echo "  make clean         Remove generated build artifacts"

setup:
	bash scripts/toolchain/setup-toolchain.sh

build: bootstrap rust-build

all: build

rust-build:
	cargo build --manifest-path tools/Cargo.toml --workspace

rust-test:
	cargo test --manifest-path tools/Cargo.toml --workspace

kernel:
	bash kernel/build.sh $(KERNEL_BUILD_DIR)

bootstrap:
	bash build/lfs-bootstrap.sh $(OUTPUT_DIR)

rootfs:
	bash build/mkrootfs.sh $(ROOTFS_DIR)

image:
	bash build/image.sh $(ROOTFS_DIR) $(IMAGE_PATH) $(BOOT_DIR)

repro-check:
	bash ci/reproducible-check.sh

qemu-smoke:
	bash ci/qemu-smoke.sh

pkg-hello:
	bash packages/hello-world/build.sh

install-hello: rootfs pkg-hello
	bash build/install-package.sh $(ROOTFS_DIR) packages/hello-world/hello-world-0.1-arm64.tar.gz

clean:
	rm -rf build/output tools/target \
		packages/hello-world/pkgroot packages/hello-world/hello-world-0.1-arm64.tar.gz
