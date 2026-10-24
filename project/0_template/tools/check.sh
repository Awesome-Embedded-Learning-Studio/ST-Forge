#!/usr/bin/env sh
# 0_template 自检:工具链、依赖、从零编译,三样一次过
# 用法:在模板目录里执行 ./tools/check.sh
set -e

TPL_DIR=$(cd "$(dirname "$0")/.." && pwd)
CUBE_DIR="$TPL_DIR/../../third_party/STM32CubeF1"

fail() { echo "[FAIL] $1"; exit 1; }

echo "== 1/3 工具链 =="
for t in arm-none-eabi-gcc cmake make openocd; do
    command -v "$t" >/dev/null 2>&1 || fail "缺少 $t,请先安装(WSL/Linux 参考环境篇 01 章)"
    echo "  ok: $t"
done

echo "== 2/3 依赖 =="
[ -f "$CUBE_DIR/Drivers/CMSIS/Device/ST/STM32F1xx/Source/Templates/system_stm32f1xx.c" ] \
    || fail "找不到 STM32CubeF1,先回仓库根执行 git submodule update --init"
echo "  ok: third_party/STM32CubeF1"

echo "== 3/3 干净编译 =="
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
cmake -S "$TPL_DIR" -B "$BUILD_DIR" >/dev/null
cmake --build "$BUILD_DIR" >/dev/null
[ -f "$BUILD_DIR/STM32F1.elf" ] || fail "没编出 STM32F1.elf"
[ -f "$BUILD_DIR/STM32F1.bin" ] || fail "没编出 STM32F1.bin"
arm-none-eabi-size --format=berkeley "$BUILD_DIR/STM32F1.elf"
echo "[PASS] 模板从零编出固件,自检通过"
