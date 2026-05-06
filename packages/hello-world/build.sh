#!/usr/bin/env bash
set -euo pipefail
PKG_ROOT="$(pwd)/pkgroot"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT"/usr/bin
cat > "$PKG_ROOT"/usr/bin/hello <<'EOF'
#!/bin/sh
echo "Hello from Alloy-Linux!"
EOF
chmod +x "$PKG_ROOT"/usr/bin/hello
tar -C "$PKG_ROOT" -czf hello-world-0.1-arm64.tar.gz .
echo "Built: hello-world-0.1-arm64.tar.gz"
