#!/usr/bin/env bash
# 按 .repos 拉取依赖；SDK 必须落在 third_party/，不能落进 src/。
set -euo pipefail

DIESEL_WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v vcs >/dev/null 2>&1; then
    echo "缺少 vcstool，请先安装：paru -S python-vcstool（或 pipx install vcstool）" >&2
    exit 1
fi

cd "$DIESEL_WS_ROOT"
vcs import --input "$DIESEL_WS_ROOT/.repos" "$DIESEL_WS_ROOT"

# 上游包自己带 submodule（pb2025_sentry_nav 有 7 个：point_lio、livox_ros_driver2、
# small_gicp_relocalization 等）。vcs 只 checkout 父仓，不会跟进 submodule，
# 缺了它们 point_lio 等包根本不存在，仿真链会在 launch 阶段报 package not found。
submodules=0
while IFS= read -r gitdir; do
    repo="$(dirname "$gitdir")"
    if [[ -f "$repo/.gitmodules" ]]; then
        echo "初始化 submodule：${repo#"$DIESEL_WS_ROOT"/}"
        git -C "$repo" submodule update --init --recursive
        submodules=$((submodules + 1))
    fi
done < <(find "$DIESEL_WS_ROOT/src" -maxdepth 3 -name .git -prune)

if [[ -d "$DIESEL_WS_ROOT/src/third_party/livox_sdk2" ]]; then
    echo "错误：SDK 被导入到 src/，请检查 .repos 的键名与导入根目录" >&2
    exit 1
fi

if [[ ! -f "$DIESEL_WS_ROOT/third_party/livox_sdk2/CMakeLists.txt" ]]; then
    echo "错误：未找到 third_party/livox_sdk2/CMakeLists.txt" >&2
    exit 1
fi

# MVS 为私有仓：拉取失败通常是没有凭据，而不是网络问题，单列提示。
if [[ ! -f "$DIESEL_WS_ROOT/third_party/mvs_sdk/include/MvCameraControl.h" ]]; then
    echo "错误：未找到 third_party/mvs_sdk/include/MvCameraControl.h" >&2
    echo "      mvs_sdk 是私有仓，请先配置 GitHub 凭据（token 或部署密钥）后重试" >&2
    exit 1
fi

echo "依赖已导入：third_party/livox_sdk2、third_party/mvs_sdk；初始化了 $submodules 个带 submodule 的上游仓"
