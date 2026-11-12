# 关键工程决策日志

> 记录 fork patch、换版本、**破坏性接口变更**、架构取舍。
> 格式见 `foray_docs/repository_structure.md` §7.2。

---

## Decision

Date: 2026-02-19

Context: 本仓从 0 初始化。需要确定它在整体架构中的位置与依赖边界。

Decision: 本仓定位为 **META** 层，owner 角色为「架构」，
依赖层级 无。

Reason:
- 切分判据 C1–C6 见 `foray_docs/repository_structure.md` §1
- 粒度结论：**一个仓 = 一个团队角色 + 一个变更率档位**
- **零业务代码。** 整机 tag = 可复现的「那一台能跑的车」

Alternatives:
- 并入相邻仓（减少仓库数量，但违反团队边界或变更率差异）

Rejected:
- 按 ROS 2 package 粒度切仓 —— 会导致版本矩阵地狱
- 按分层机械切仓 —— 会切断团队边界（Conway）

---

## Decision

Date: 2026-10-19

Context: `foray_platform_driver_livox` 直接封装 Livox SDK2，需要确定 SDK 是否
fork 到组织、如何固定版本、开发机与实机如何取得 SDK。

Decision:
- **不 fork、不使用 git submodule、不使用 FetchContent**；Livox-SDK2 无源码修改，
  构建参数（CMake policy、`-include cstdint`）由脚本处理，不构成 patch；
- 在 `.repos` 中 pin `third_party/livox_sdk2` 到 commit
  `f5d9375f84efe2b15bc0a052d3e18482ed13adf4`（v1.3.1）；
- SDK 放在 `src/` 之外，配合 `third_party/COLCON_IGNORE` 与
  `colcon build --base-paths src`，避免被 colcon 当成包；
- 开发机用 `scripts/build_livox_sdk2.sh` 装到
  `~/.cache/foray-platform-prefix/livox-sdk2`；实机镜像固定
  `/opt/foray/livox-sdk2`；
- 驱动 CMake 默认 `FORAY_BUILD_DRIVER_LIVOX=OFF`（stub + mock）；
  启用真实 SDK 时用 `ON` + `PREBUILT` + `LIVOX_SDK2_ROOT`。

Reason:
- 组织规范明确禁止 submodule，厂商 SDK 源码/二进制不得入库；
- 不修改上游时 fork 只会增加同步与许可维护成本；
- `.repos` + 私有前缀让开发机、CI、实机使用同一 commit，且仓库保持干净。

Alternatives:
- fork `Livox-SDK2-foray-fork`：仅在未来必须打 patch 时启用；
- FetchContent：configure 阶段隐式联网，pin 绕过 `.repos` 单一清单；
- 系统包管理器：版本不可控，只能作为次要 `SYSTEM` provider。

Rejected:
- 把 SDK 源码或 `.so` 提交进任何仓库；
- 在 `src/` 下放置第三方 SDK 源码；
- 开发测试强制依赖真实 SDK。

---

## Decision

Date: 2026-10-23

Context: `foray_platform_driver_hikvision` 需要海康 MVS SDK（闭源，无公开源码，
无法像 Livox-SDK2 那样自行构建）。上一轮决策（2026-10-19）写明「厂商 SDK 源码/二进制
不得入库」，对闭源 SDK 不成立：实机与 CI 必须能拿到二进制，否则无法构建真实驱动。

Decision:
- MVS SDK（7 个头文件 + amd64/arm64 主库 `libMvCameraControl.so`）放在**组织私有仓**
  `ZQU-Foray/mvs-sdk`（private），`.repos` 中 pin `third_party/mvs_sdk` 到 commit
  `353b584614f42fc286b9f684735f6479401e63d6`（V4.1.2.2 + 插件/打包脚本）；
- 该仓**只承载分发**：不含业务代码、不参与 colcon、不被任何产品源码仓包含；
  访问边界由 private 可见性提供，不公开托管、不再分发；
- **传输层插件不入库**（体积大、随官方包版本变化）：由
  `third_party/mvs_sdk/scripts/install-plugins.sh` 从官方安装包按架构补齐，
  `make-bundle.sh` 可打成 tar.gz 分发；
- 开发机用 `scripts/install_mvs_sdk.sh` 装到
  `~/.cache/foray-platform-prefix/mvs-sdk`，实机镜像固定 `/opt/foray/mvs-sdk`；
- 驱动 CMake 默认 `FORAY_BUILD_DRIVER_HIKVISION=OFF`（stub + mock），启用时
  找不到 SDK 必须 `FATAL_ERROR`。

Reason:
- 闭源 SDK 的二进制只有两种取得方式：厂商安装包（版本不可控、含 GUI 工具、
  CI 无法复现）或自建分发仓；后者才能让开发机、CI、实机 pin 同一份字节；
- 拆分「主库入库 / 插件脚本补齐」既满足可复现，又避免几 MB 的插件与官方包重复存储；
- **修订 2026-10-19 条目**：其中「厂商 SDK 二进制不得入库」收敛为
  「不得入**产品源码仓**」；闭源 SDK 的二进制统一收敛到组织私有分发仓。
  Livox 仍维持「不入库」——它可从源码构建，不需要分发二进制。

Alternatives:
- 只依赖系统 `/opt/MVS` 官方安装：版本不可控，CI 无法复现构建；
- 把二进制放进 `foray_platform` 产品仓：违反分层与源码仓纯净，且下游全部拖大。

Rejected:
- 把 MVS 二进制提交进任何**产品源码仓**；
- 把传输层插件提交进 `mvs-sdk`（体积大且与官方安装包重复）；
- 公开托管 MVS 二进制（违反海康许可与组织合规）。

