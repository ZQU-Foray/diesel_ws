#!/usr/bin/env bash
# 从 .repos pin 的 Livox-SDK2 源码构建并安装到私有前缀。
#
# 环境变量：
#   FORAY_LIVOX_SDK2_PREFIX     安装前缀，默认 ~/.cache/foray-platform-prefix/livox-sdk2
#   FORAY_LIVOX_SDK2_BUILD_DIR  构建目录，默认 ~/.cache/foray-build/livox-sdk2
set -euo pipefail

FORAY_WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$FORAY_WS_ROOT/third_party/livox_sdk2"
PREFIX="${FORAY_LIVOX_SDK2_PREFIX:-$HOME/.cache/foray-platform-prefix/livox-sdk2}"
BUILD_DIR="${FORAY_LIVOX_SDK2_BUILD_DIR:-$HOME/.cache/foray-build/livox-sdk2}"
LIBRARY="$PREFIX/lib/liblivox_lidar_sdk_shared.so"

if [[ -f "$LIBRARY" ]]; then
    echo "Livox SDK2 已安装：$LIBRARY"
    exit 0
fi

if [[ ! -f "$SOURCE_DIR/CMakeLists.txt" ]]; then
    echo "缺少 SDK 源码，请先运行 scripts/import_repos.sh" >&2
    exit 1
fi

# v1.3.1 的 CMake 最低版本声明较旧，新 CMake 需要放宽策略；
# 新 GCC 下 file_manager.h 缺少 <cstdint>，用编译参数注入。
cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CXX_FLAGS="-include cstdint"
cmake --build "$BUILD_DIR" -j"$(nproc)"
cmake --install "$BUILD_DIR"

if [[ ! -f "$LIBRARY" ]]; then
    echo "安装后未找到 $LIBRARY" >&2
    exit 1
fi

echo "Livox SDK2 安装完成：$PREFIX"
