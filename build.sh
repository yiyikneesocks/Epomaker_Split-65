#!/usr/bin/env bash
# Rebuild EPOMAKER Split65 custom firmware from the upstream baseline.
# Usage: ./build.sh [v3.3|v4]        (historical editions)
#        ./build.sh v5 a|b           (v5-A deep-sleep / v5-B always-awake, default b)
# Network-restricted? export UPSTREAM='https://gh-proxy.com/https://github.com/SRGBmods/EpomakerQMK.git'
set -euo pipefail
VER="${1:-v5}"
ED="${2:-b}"
BASE_COMMIT=10dfd3e8
UPSTREAM="${UPSTREAM:-https://github.com/SRGBmods/EpomakerQMK.git}"
PATCH="patches/split65-${VER}.patch"

command -v make >/dev/null || { echo "need make"; exit 1; }
command -v arm-none-eabi-gcc >/dev/null || { echo "need gcc-arm-none-eabi (sudo apt install gcc-arm-none-eabi libnewlib-arm-none-eabi)"; exit 1; }
[ -f "$PATCH" ] || { echo "run from repo root"; exit 1; }

git clone --depth 50 "$UPSTREAM" Split65-firmware
cd Split65-firmware
git fetch --depth 50 origin "$BASE_COMMIT" 2>/dev/null || true
git checkout "$BASE_COMMIT" 2>/dev/null || git checkout origin/master
git apply "../$PATCH"

/usr/bin/python3 -m venv .venv
. .venv/bin/activate
pip install -q -U pip && pip install -q -r requirements.txt qmk
qmk config user.qmk_home="$PWD"

if [ "$VER" = "v5" ] && [ "$ED" = "b" ]; then
  make epomaker/split65:default LINK_WATCH_ALWAYS=yes
else
  make epomaker/split65:default
fi
echo "OK: .build/epomaker_split65_default.bin  (flash BOTH halves; edition: v5-$ED)"
