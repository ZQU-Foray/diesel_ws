# 开发计划

## 任务列表

- [x] 写 `.repos` 骨架（先 pin 第三方上游包）
  - 已 pin Livox-SDK2 v1.3.1（commit `f5d9375f`）
  - 已 pin 海康 MVS SDK V4.1.2.2（私有仓 `ZQU-Foray/mvs-sdk`，commit `353b584`）
- [ ] 把当前 `foray_navigation` fork 也作为 pin 项（M3）
- [ ] 搭集成 CI（按 `.repos` 拉全量 → 全量 build）
- [x] 写一键脚本（拉取 / 构建；启动待装配根）
- [ ] 打第一个整机 tag（M6）

## 当前 Agent State

LIVOX_SDK_PINNED + MVS_SDK_PINNED

## Before Snapshot

commit hash:   6f0fd98
branch:        dev
modified files: `.repos`、`.gitignore`、`README.md`、`VERSIONS.md`、`decision.md`、`plan.md`、`tree.md`；新增 `third_party/COLCON_IGNORE` 与 `scripts/`
risk level:    L1

## 模糊点与待确认项

- 本仓接口尚未冻结，任务清单为**方向性**的，落地顺序以 `foray_docs/algorithm_structure.md` §9 演进阶段为准
- 依赖的自研仓尚未建齐，跨仓任务需等对方 `README.md` 明确接口后再启动
- Livox SDK2 开发机默认装到 `~/.cache/foray-platform-prefix/livox-sdk2`；
  实机镜像固定 `/opt/foray/livox-sdk2`（通过 `FORAY_LIVOX_SDK2_PREFIX` 覆盖）
- 海康 MVS SDK 开发机默认装到 `~/.cache/foray-platform-prefix/mvs-sdk`；
  实机镜像固定 `/opt/foray/mvs-sdk`（通过 `FORAY_MVS_PREFIX` 覆盖）。
  传输层插件需从海康官方安装包补齐，`mvs-sdk` 仓内不含

## Vector Backend Status

Backend: Markdown
Status:  ready
Environment: 仓库内 Markdown 文档（无外部向量后端）
Index: 本仓 `README.md` / `tree.md` / `decision.md`
Initialization: 2026-02-19
Commit: （首次提交）

## Acceptance Criteria

- [x] `.repos` 可被 vcstool 解析，Livox SDK2 pin 到 v1.3.1 commit
- [x] `.repos` 可被 vcstool 解析，MVS SDK pin 到 V4.1.2.2 commit（私有仓需凭据）
- [x] 提供拉取 / 构建 / 环境脚本
- [ ] 本仓能独立 `colcon build`（无代码时跳过）
- [ ] CI 绿灯
- [ ] 每个新增模块带独立可执行测试
