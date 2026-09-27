#!/usr/bin/env bash
#
# download_libbox.sh
# Downloads the official prebuilt Libbox.xcframework from sing-box releases
#

set -e

VERSION="v1.10.7"
FRAMEWORK_DIR="NATunnelPacketTunnel/Frameworks"

echo "==> Preparing Libbox.xcframework for NA Tunnel iOS..."
mkdir -p "$FRAMEWORK_DIR"
cd "$FRAMEWORK_DIR"

if [ -d "Libbox.xcframework" ]; then
    echo "==> Libbox.xcframework already exists. Skipping download."
    exit 0
fi

echo "==> Downloading Libbox.xcframework ($VERSION)..."
DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/${VERSION}/libbox-apple-darwin.tar.gz"

curl -L "$DOWNLOAD_URL" -o "libbox.tar.gz"
echo "==> Extracting Libbox.xcframework..."
tar -xzf "libbox.tar.gz"
rm -f "libbox.tar.gz"

echo "==> Libbox.xcframework setup complete!"
