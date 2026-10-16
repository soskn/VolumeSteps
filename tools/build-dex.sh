#!/usr/bin/env bash
# =====================================================================
#  build-dex.sh - compile the unregister helper to DEX
#  编译注销辅助程序为 DEX
#
#  EN: Compiles tools/RmOv.java into module/bin/unregister.dex.
#      Requires a JDK (javac) and the Android d8 tool. Set D8 to the d8
#      launcher/jar path if it is not on your PATH.
#  CN: 将 tools/RmOv.java 编译为 module/bin/unregister.dex。
#      需要 JDK（javac）以及 Android 的 d8 工具。若 d8 不在 PATH 中，
#      请用 D8 变量指定其路径。
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/tools/RmOv.java"
OUT_DIR="$ROOT/build/dex"
OUT_DEX="$ROOT/module/bin/unregister.dex"

# EN: d8 can be a launcher script (D8=d8) or a jar (D8="java -cp ... d8.jar").
# CN: d8 可以是启动脚本（D8=d8），也可以是 jar（D8="java -cp ... d8.jar"）。
D8="${D8:-d8}"

mkdir -p "$OUT_DIR" "$(dirname "$OUT_DEX")"

echo ">> javac"
javac -d "$OUT_DIR" "$SRC"

echo ">> d8"
# EN: --min-api 30 is plenty (device is API 36). d8 writes classes.dex into
#     an existing output directory. / CN: --min-api 30 足够（设备为 API 36）。
#     d8 会把 classes.dex 写入一个已存在的输出目录。
mkdir -p "$OUT_DIR/dexout"
$D8 --min-api 30 --output "$OUT_DIR/dexout" "$OUT_DIR/RmOv.class"

cp "$OUT_DIR/dexout/classes.dex" "$OUT_DEX"
echo "OK -> $OUT_DEX"
