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

# small_gicp_relocalization 的 CMake 先 find_package(small_gicp)，找不到就
# FetchContent 去 GitHub 拉 master（浮动，且离线必失败）。这里先把 .repos pin 住的
# third_party/small_gicp 装进 third_party_install/，再让 FetchContent 直接用它。
SMALL_GICP_SRC="$FORAY_WS_ROOT/third_party/small_gicp"
SMALL_GICP_PREFIX="$FORAY_WS_ROOT/third_party_install"
if [[ -f "$SMALL_GICP_SRC/CMakeLists.txt" ]]; then
    if [[ ! -f "$SMALL_GICP_PREFIX/lib/cmake/small_gicp/small_gicp-config.cmake" ]]; then
        echo "构建 small_gicp -> third_party_install/"
        cmake -S "$SMALL_GICP_SRC" -B "$SMALL_GICP_SRC/build" \
            -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}" \
            -DCMAKE_INSTALL_PREFIX="$SMALL_GICP_PREFIX" \
            -DBUILD_EXAMPLES=OFF -DBUILD_BENCHMARKS=OFF \
            -DBUILD_TESTS=OFF -DBUILD_PYTHON_BINDINGS=OFF
        cmake --build "$SMALL_GICP_SRC/build" -j"$(nproc)"
        cmake --install "$SMALL_GICP_SRC/build"
    fi
    CMAKE_ARGS+=(
        -DFETCHCONTENT_SOURCE_DIR_SMALL_GICP="$SMALL_GICP_SRC"
        -DFETCHCONTENT_FULLY_DISCONNECTED=ON
        # 上游 CMake 认的是裸目标名 `small_gicp`，而 pin 住的 small_gicp 导出
        # `small_gicp::small_gicp`；一旦 find_package 命中就只剩 -lsmall_gicp、丢 include。
        # 因此固定走 FetchContent（源码来自本地 pin），不让 find_package 抢先命中。
        -DCMAKE_DISABLE_FIND_PACKAGE_small_gicp=ON
    )
fi

cd "$FORAY_WS_ROOT"
# 缺少系统依赖时可临时跳过个别包，例如宿主未装 camera_info_manager：
#   FORAY_SKIP_PACKAGES="rmoss_cam rmoss_gz_cam" scripts/colcon_build.sh
SKIP_ARGS=()
if [[ -n "${FORAY_SKIP_PACKAGES:-}" ]]; then
    # shellcheck disable=SC2206  # 有意按空格拆成包名列表
    SKIP_ARGS=(--packages-skip ${FORAY_SKIP_PACKAGES})
    echo "跳过包：$FORAY_SKIP_PACKAGES"
fi

colcon build \
    --base-paths "$FORAY_WS_ROOT/src" \
    --symlink-install \
    "${SKIP_ARGS[@]}" \
    --cmake-args "${CMAKE_ARGS[@]}"
