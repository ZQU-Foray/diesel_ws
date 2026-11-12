#!/usr/bin/env bash
# Diesel 命名门禁：仓内不得残留 `foray` 系统命名（战队文案与迁移前必须保留的标识除外）。
#
# 为什么需要：改名是跨 11 个仓的机械动作，靠人眼 review 必然漏；把「残留」变成
# exit code，才可能在 CI 和本地各跑一次都对得上（见 foray_docs/diesel_naming_migration.md §4）。
#
# 用法：
#   scripts/check_naming.sh            # 检查本仓（git ls-files 范围）
#   scripts/check_naming.sh <dir>...   # 检查指定目录（不做 git 过滤）
#
# 白名单（逐条给理由，新增必须写清为什么）：
#   ZQU-Foray            组织名，不改
#   foray_docs           战队级文档仓，不改名
#   foray-fork           fork 仓后缀硬规则（repository_structure.md §4.1）
#   Foray / FORAY        战队名与版权头（系统代号是 Diesel，战队还是 Foray）
#   foray_mcu            下位机两仓不在 L1–L5，不改名
#   foray_web            战队门户，归文档类
#   foray-HelloWorld     教学仓，不改名
#   foray_localization   P4 远程改名前的仓名引用（.repos 注释 / 文档链接）
#   foray_sim_ws         已删除的临时沙箱目录名，仅作为历史叙述出现在 plan.md
set -o pipefail

X

if (($# > 0)); then
    files=$(find "$@" -type f \
        -not -path '*/.git/*' -not -path '*/build*/*' -not -path '*/install*/*' \
        -not -path '*/log/*' -not -path '*/__pycache__/*' -not -path '*/third_party_install/*')
elif git rev-parse --git-dir >/dev/null 2>&1; then
    files=$(git ls-files)
else
    echo "既没有指定目录，也不在 git 仓库里" >&2
    exit 2
fi

hits=$(grep -nI -i 'foray' $files 2>/dev/null | grep -Ev "$WHITELIST" || true)
if [[ -n "$hits" ]]; then
    echo "$hits"
    echo "结论：存在 Diesel 迁移未覆盖的 foray 命名，逐条确认或补进白名单并写明理由。" >&2
    exit 1
fi
echo "命名门禁通过：白名单外无 foray 残留。"
