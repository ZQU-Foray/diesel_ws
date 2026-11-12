#!/usr/bin/env bash
# 安装海康 MVS SDK 到私有前缀。
#
# 与 Livox 不同，MVS 是闭源二进制，无法从源码构建：本脚本把 `.repos` pin 的
# `third_party/mvs_sdk` 安装到私有前缀，供 foray_platform 驱动的
# `FORAY_MVS_ROOT` 使用。
#
# 环境变量：
#   FORAY_MVS_PREFIX   安装前缀，默认 ~/.cache/foray-platform-prefix/mvs-sdk
#
# 用法：
#   scripts/import_repos.sh                          # 先拉取 SDK
#   scripts/install_mvs_sdk.sh                       # 只装头文件 + 双架构主库
#   scripts/install_mvs_sdk.sh --package <官方包>    # 同时补齐传输层插件
#
# 传输层插件（libMvUsb3vTL.so / libMVGigEVisionSDK.so …）不在 mvs-sdk 仓库内，
# 必须从海康官方 MVS Linux 安装包补齐，否则表现为枚举正常但打不开设备。
set -euo pipefail

FORAY_WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$FORAY_WS_ROOT/third_party/mvs_sdk"
PREFIX="${FORAY_MVS_PREFIX:-$HOME/.cache/foray-platform-prefix/mvs-sdk}"
PACKAGE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix) PREFIX="${2:?--prefix 需要一个路径}"; shift 2 ;;
        --package) PACKAGE="${2:?--package 需要官方安装包路径}"; shift 2 ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
        *) echo "未知参数：$1" >&2; exit 2 ;;
    esac
done

if [[ ! -f "$SOURCE_DIR/include/MvCameraControl.h" ]]; then
    echo "缺少 MVS SDK，请先运行 scripts/import_repos.sh" >&2
    exit 1
fi

if [[ -f "$PREFIX/lib/libMvCameraControl.so" ]]; then
    echo "MVS SDK 主库已安装：$PREFIX/lib/libMvCameraControl.so"
else
    bash "$SOURCE_DIR/scripts/install.sh" --prefix "$PREFIX"
fi

if [[ -n "$PACKAGE" ]]; then
    bash "$SOURCE_DIR/scripts/install-plugins.sh" --package "$PACKAGE" --prefix "$PREFIX"
else
    echo "未指定 --package：跳过传输层插件。缺插件时设备能枚举但打不开/取不到帧。" >&2
fi

echo
echo "MVS SDK 就绪：$PREFIX"
echo "  构建期：-DMVS_ROOT=$SOURCE_DIR 或 -DCMAKE_PREFIX_PATH=$PREFIX"
echo "  运行期：LD_LIBRARY_PATH 需包含 $PREFIX/lib（source scripts/env.sh 已设置）"
