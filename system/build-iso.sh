#!/usr/bin/env bash
set -o pipefail
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

# ── plasmex derlemesi ──────────────────────────────────────────────────────
# Canlı imaja shell binary'si KOŞULSUZ girmeli (v0.1 ISO'su binary'siz
# kalmıştı: oturum plasmex'i sessizce atlayıp SDDM'ye dönüyordu).
# Gereksinimler: build-essential cmake qt6-base-dev qt6-declarative-dev
#                qt6-wayland-dev  (CI ISO job'u kurar).
SHELL_BUILD="/tmp/xos-shell-build"
SHELL_STAGE="/tmp/xos-shell-stage"
SHELL_LOG="/tmp/xos-shell-build.log"
stage_shell() {
    rm -rf "$SHELL_BUILD" "$SHELL_STAGE"
    echo "→ plasmex yapılandırılıyor (CMAKE_INSTALL_PREFIX=/usr)…"
    if ! cmake -S "$REPO" -B "$SHELL_BUILD" \
            -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
            > "$SHELL_LOG" 2>&1; then
        echo "✗ cmake yapılandırması başarısız — son 40 satır:" >&2
        tail -n 40 "$SHELL_LOG" >&2
        return 1
    fi
    echo "→ plasmex derleniyor…"
    if ! cmake --build "$SHELL_BUILD" -j"$(nproc)" >> "$SHELL_LOG" 2>&1; then
        echo "✗ plasmex derlemesi başarısız — son 40 satır:" >&2
        tail -n 40 "$SHELL_LOG" >&2
        return 1
    fi
    if ! DESTDIR="$SHELL_STAGE" cmake --install "$SHELL_BUILD" >> "$SHELL_LOG" 2>&1; then
        echo "✗ cmake --install başarısız — son 40 satır:" >&2
        tail -n 40 "$SHELL_LOG" >&2
        return 1
    fi
    mkdir -p "$REPO/system/live-build/config/includes.chroot/usr"
    cp -a "$SHELL_STAGE/usr/." "$REPO/system/live-build/config/includes.chroot/usr/"
    if [ ! -x "$REPO/system/live-build/config/includes.chroot/usr/bin/plasmex" ]; then
        echo "✗ includes.chroot/usr/bin/plasmex kurulamadı" >&2
        return 1
    fi
    echo "✓ plasmex imaja hazır (includes.chroot/usr/bin/plasmex)"
}

if [ "${XOS_ISO_ALLOW_NO_SHELL:-0}" = "1" ]; then
    echo "⚠ XOS_ISO_ALLOW_NO_SHELL=1 — binary'siz ISO istendi (bilinçli)"
elif ! stage_shell; then
    echo "✗ shell derlenemedi. qt6-base-dev / qt6-declarative-dev / qt6-wayland-dev kurulu mu?" >&2
    echo "  (Binary'siz ISO için bilinçli olarak: XOS_ISO_ALLOW_NO_SHELL=1)" >&2
    exit 1
fi

echo "→ lb build (bu uzun sürebilir)"
mkdir -p "$OUT"
set +e
lb build 2>&1 | tee "$OUT/build.log"
STATUS=$?
set -e
echo "→ lb build çıkış kodu: $STATUS"

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
