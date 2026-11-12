#!/usr/bin/env bash
# 校验工作区里的实际 commit 与本仓 .repos 是否一致。
#
# 用法：
#   scripts/check_repos_drift.sh              # 检查本仓根（diesel_ws 自己）
#   scripts/check_repos_drift.sh <workspace>  # 检查任一由 .repos 长出来的工作区
#
# 比对按 **URL** 而非路径：本地沙箱把 small_gicp 放在 deps/，本仓规范放 third_party/，
# 路径不同不等于漂移（见 decision.md 2026-11-12）。
# 退出码：0 = 无 commit 漂移；1 = 有同 URL 不同 commit，或工作区缺 vcstool。

set -euo pipefail

DIESEL_WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${1:-$DIESEL_WS_ROOT}"

if ! command -v vcs >/dev/null 2>&1; then
    echo "缺少 vcstool：pip install vcstool" >&2
    exit 1
fi

python3 - "$DIESEL_WS_ROOT/.repos" "$WORKSPACE" <<'PY'
import os
import re
import subprocess
import sys

repos_path, workspace = sys.argv[1], sys.argv[2]


def parse_repos(path):
    """解析 .repos：只认 `  path:` 与 `    url|version:` 两种缩进层级。"""
    entries, path_key = {}, None
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            head = re.match(r"^  (\S+):$", line)
            if head:
                path_key = head.group(1)
                entries[path_key] = {}
                continue
            field = re.match(r"^    (url|version|type):\s*(\S+)$", line)
            if field and path_key:
                entries[path_key][field.group(1)] = field.group(2)
    return entries


def normalize(url):
    """协议、`git@` 形式、尾部 `.git` 都不该影响比对。"""
    url = url.strip().lower()
    url = re.sub(r"^git@([^:]+):", r"https://\1/", url)
    url = re.sub(r"^ssh://git@([^/]+)/", r"https://\1/", url)
    # 反代前缀（如 ghproxy.net/https://github.com/…）只改下载路径，不改仓库身份：
    # 先剥掉一层，否则同一仓库会被判成「未入账」。
    url = re.sub(r"^https?://[^/]+/https?://", "", url)
    url = re.sub(r"^https?://", "", url)
    url = re.sub(r"/+$", "", url)
    return url[:-4] if url.endswith(".git") else url


expected = parse_repos(repos_path)

# 本仓根自己也是一个 git 仓库，`vcs export .` 只会吐出 diesel_ws 本身、不下潜；
# 因此按 .repos 键的一级目录逐个导出（src、third_party…），再拼回带前缀的路径。
actual = {}
tops = sorted({key.split("/", 1)[0] for key in expected})
for top in tops:
    export = subprocess.run(
        ["vcs", "export", "--exact", os.path.join(workspace, top)],
        capture_output=True,
        text=True,
        check=False,
    )
    if export.returncode != 0:
        continue  # 目录还不存在：由 missing 分支报「未导入」
    current = None
    for raw in export.stdout.splitlines():
        entry = re.match(r"^  (\S+):$", raw)
        field = re.match(r"^    (url|version):\s*(\S+)$", raw)
        if entry:
            current = f"{top}/{entry.group(1)}"
            actual[current] = {}
        elif field and current:
            actual[current][field.group(1)] = field.group(2)

expected_by_url = {normalize(item.get("url", "")): (key, item) for key, item in expected.items()}
actual_by_url = {normalize(item.get("url", "")): item for item in actual.values()}

mismatch, missing, extra = [], [], []
for url, (key, item) in expected_by_url.items():
    found = actual_by_url.get(url)
    if found is None:
        missing.append(key)
    elif found.get("version") != item.get("version"):
        mismatch.append((key, item.get("version", "?"), found.get("version", "?")))
for url, item in actual_by_url.items():
    if url not in expected_by_url:
        extra.append(item.get("url", url))

for key, want, got in mismatch:
    print(f"漂移 {key}: .repos={want} 实际={got}")
for key in missing:
    print(f"未导入 {key}（vcs import 后应出现）")
for url in extra:
    print(f"未入账 {url}（用了但 .repos 里没有）")

if mismatch:
    print("结论：commit 漂移，先按 .repos 重建再继续。", file=sys.stderr)
    sys.exit(1)

print(f"结论：{len(expected)} 条 pin 无 commit 漂移"
      f"（未导入 {len(missing)} 项，未入账 {len(extra)} 项）")
PY
