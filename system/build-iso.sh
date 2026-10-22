#!/bin/sh
# build-iso.sh — X-OS canlı ISO'sunu live-build ile üretir.
# Gereksinimler: Debian/Ubuntu host, sudo, live-build (lb).
# Kullanım:      sudo ./system/build-iso.sh [--clean]
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO=$(CDPATH= cd -- "$ROOT/.." && pwd)
LB_DIR="$ROOT/live-build"
OUT="$REPO/out/iso"

if [ "$(id -u)" -ne 0 ]; then
    echo "Hata: bu script sudo ile çalıştırılmalı (live-build chroot gerekir)." >&2
    exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
    echo "live-build kurulu değil. Kurulum:" >&2
    echo "  sudo apt install live-build" >&2
    exit 1
fi

if [ "${1:-}" = "--clean" ]; then
    echo "→ Temizleniyor: $LB_DIR/build $LB_DIR/.build"
    rm -rf "$LB_DIR/build" "$LB_DIR/.build"
fi

# auto/config her çalıştırmada proje ayarlarını uygular.
cd "$LB_DIR"

if [ ! -e .build/config ]; then
    echo "→ lb config"
    ./auto/config
fi

echo "→ lb build (bu uzun sürebilir)"
mkdir -p "$OUT"
set +e
lb build 2>&1 | tee "$OUT/build.log"
STATUS=$?
set -e

ISO=$(find . -maxdepth 1 -name '*.iso' -type f | head -n 1)
if [ -n "$ISO" ]; then
    mv -f "$ISO" "$OUT/"
    echo "✓ ISO: $OUT/$(basename "$ISO")"
    cd "$OUT"
    sha256sum "$(basename "$ISO")" > SHA256SUMS
    cat SHA256SUMS
else
    echo "✗ ISO üretilemedi (lb çıkış kodu $STATUS). Günlük: $OUT/build.log" >&2
    exit 1
fi
