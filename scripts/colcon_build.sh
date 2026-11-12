#!/usr/bin/env bash
# 统一 colcon 构建入口：固定 --base-paths src，避免把 third_party 当成包。
#
#   scripts/colcon_build.sh                 # 驱动默认 stub（OFF）
#   FORAY_LIVOX_SDK=ON scripts/colcon_build.sh
set -euo pipefail

FORAY_WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/env.sh
source "$FORAY_WS_ROOT/scripts/env.sh"

if ! command -v colcon >/dev/null 2>&1; then
    echo "缺少 colcon，请先安装 ROS 2 开发环境" >&2
    exit 1
fi

if [[ ! -d "$FORAY_WS_ROOT/src" ]] ||
   [[ -z "$(find "$FORAY_WS_ROOT/src" -name package.xml -print -quit)" ]]; then
    echo "src/ 下尚无 ROS 包，跳过 colcon build（先按 .repos 加入自研仓）"
    exit 0
fi

LIVOX_SDK_MODE="${FORAY_LIVOX_SDK:-OFF}"
CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
    -DFORAY_BUILD_DRIVER_LIVOX="$LIVOX_SDK_MODE"
)

if [[ "$LIVOX_SDK_MODE" == "ON" ]]; then
    CMAKE_ARGS+=(
        -DFORAY_LIVOX_SDK_PROVIDER=PREBUILT
        -DLIVOX_SDK2_ROOT="$LIVOX_SDK2_ROOT"
    )
fi

cd "$FORAY_WS_ROOT"
colcon build \
    --base-paths "$FORAY_WS_ROOT/src" \
    --symlink-install \
    --cmake-args "${CMAKE_ARGS[@]}"
