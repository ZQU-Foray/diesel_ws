#!/usr/bin/env bash
# 按 .repos 拉取依赖；SDK 必须落在 third_party/，不能落进 src/。
set -euo pipefail

FORAY_WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v vcs >/dev/null 2>&1; then
    echo "缺少 vcstool，请先安装：paru -S python-vcstool（或 pipx install vcstool）" >&2
    exit 1
fi

cd "$FORAY_WS_ROOT"
vcs import --input "$FORAY_WS_ROOT/.repos" "$FORAY_WS_ROOT"

if [[ -d "$FORAY_WS_ROOT/src/third_party/livox_sdk2" ]]; then
    echo "错误：SDK 被导入到 src/，请检查 .repos 的键名与导入根目录" >&2
    exit 1
fi

if [[ ! -f "$FORAY_WS_ROOT/third_party/livox_sdk2/CMakeLists.txt" ]]; then
    echo "错误：未找到 third_party/livox_sdk2/CMakeLists.txt" >&2
    exit 1
fi

# MVS 为私有仓：拉取失败通常是没有凭据，而不是网络问题，单列提示。
if [[ ! -f "$FORAY_WS_ROOT/third_party/mvs_sdk/include/MvCameraControl.h" ]]; then
    echo "错误：未找到 third_party/mvs_sdk/include/MvCameraControl.h" >&2
    echo "      mvs_sdk 是私有仓，请先配置 GitHub 凭据（token 或部署密钥）后重试" >&2
    exit 1
fi

echo "依赖已导入：third_party/livox_sdk2、third_party/mvs_sdk"
