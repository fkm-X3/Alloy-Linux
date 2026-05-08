SHELL := bash
POWERSHELL ?= pwsh

OUTPUT_DIR ?= ./build/output
ROOTFS_DIR ?= $(OUTPUT_DIR)/rootfs
BOOT_DIR ?= $(OUTPUT_DIR)/boot
IMAGE_PATH ?= $(OUTPUT_DIR)/alloy-orangepi5.img
KERNEL_BUILD_DIR ?= $(OUTPUT_DIR)/kernel

.PHONY: help setup setup-host doctor build all rust-build rust-test kernel bootstrap rootfs image \
        repro-check qemu-smoke pkg-hello install-hello clean

help:
	@echo "Alloy-Linux common targets"
	@echo "  make setup         Validate cross toolchain and emit env file"
	@echo "  make setup-host    Validate Windows host prerequisites + emit toolchain env"
	@echo "  make doctor        Diagnose host prerequisites for build/image workflow"
	@echo "  make build         Bootstrap + build Rust workspace"
	@echo "  make kernel        Build ARM64 kernel + boot artifacts"
	@echo "  make rootfs        Create minimal rootfs layout"
	@echo "  make image         Build bootable ext4 image"
	@echo "  make rust-test     Run Rust workspace tests"
	@echo "  make repro-check   Validate reproducibility manifests"
	@echo "  make clean         Remove generated build artifacts"

setup:
	$(POWERSHELL) -NoProfile -File scripts\toolchain\setup-toolchain.ps1

setup-host:
	$(POWERSHELL) -NoProfile -File scripts\toolchain\setup-host.ps1

doctor:
	$(POWERSHELL) -NoProfile -File scripts\toolchain\setup-host.ps1 -Doctor

build:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target build

all:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target all

rust-build:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target rust-build

rust-test:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target rust-test

kernel:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target kernel

bootstrap:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target bootstrap

rootfs:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target rootfs

image:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target image

repro-check:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target repro-check

qemu-smoke:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target qemu-smoke

pkg-hello:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target pkg-hello

install-hello:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target install-hello

clean:
	$(POWERSHELL) -NoProfile -File Build.ps1 -Target clean
