#!/usr/bin/env bash
# =====================================================================
#  build.sh - package the flashable module ZIP
#  打包可刷入的模块 ZIP
#
#  EN: Builds dist/VolumeSteps-<version>.zip from the module/ folder.
#      The module files are placed at the ROOT of the zip, which is what
#      KernelSU / Magisk expects.
#  CN: 从 module/ 目录构建 dist/VolumeSteps-<version>.zip。
#      模块文件位于 zip 的根目录，这是 KernelSU / Magisk 要求的格式。
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$ROOT/module"
DIST_DIR="$ROOT/dist"

# EN: Read version from module.prop. / CN: 从 module.prop 读取版本号。
VERSION="$(grep -E '^version=' "$MODULE_DIR/module.prop" | head -n1 | cut -d= -f2- | tr -d '\r')"
NAME="VolumeSteps-${VERSION:-0}.zip"

# EN: Prefer the bundled dex; warn if missing.
# CN: 优先使用仓库内的 dex；缺失时给出警告。
if [ ! -f "$MODULE_DIR/bin/unregister.dex" ]; then
    echo "WARN: module/bin/unregister.dex missing; run tools/build-dex.sh" >&2
fi

mkdir -p "$DIST_DIR"
OUT="$DIST_DIR/$NAME"
rm -f "$OUT"

# EN: Zip module contents at the archive root, skipping dotfiles.
# CN: 将 module 内容打包到压缩包根目录，忽略点文件。
( cd "$MODULE_DIR" && zip -r -X "$OUT" . -x '.*' -x '*/.*' >/dev/null )

echo "OK -> $OUT"
unzip -l "$OUT"
