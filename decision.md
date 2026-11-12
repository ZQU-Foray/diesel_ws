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

Context: `diesel_platform_driver_livox` 直接封装 Livox SDK2，需要确定 SDK 是否
fork 到组织、如何固定版本、开发机与实机如何取得 SDK。

Decision:
- **不 fork、不使用 git submodule、不使用 FetchContent**；Livox-SDK2 无源码修改，
  构建参数（CMake policy、`-include cstdint`）由脚本处理，不构成 patch；
- 在 `.repos` 中 pin `third_party/livox_sdk2` 到 commit
  `f5d9375f84efe2b15bc0a052d3e18482ed13adf4`（v1.3.1）；
- SDK 放在 `src/` 之外，配合 `third_party/COLCON_IGNORE` 与
  `colcon build --base-paths src`，避免被 colcon 当成包；
- 开发机用 `scripts/build_livox_sdk2.sh` 装到
  `~/.cache/diesel-platform-prefix/livox-sdk2`；实机镜像固定
  `/opt/diesel/livox-sdk2`；
- 驱动 CMake 默认 `DIESEL_BUILD_DRIVER_LIVOX=OFF`（stub + mock）；
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

Context: `diesel_platform_driver_hikvision` 需要海康 MVS SDK（闭源，无公开源码，
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
  `~/.cache/diesel-platform-prefix/mvs-sdk`，实机镜像固定 `/opt/diesel/mvs-sdk`；
- 驱动 CMake 默认 `DIESEL_BUILD_DRIVER_HIKVISION=OFF`（stub + mock），启用时
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
- 把二进制放进 `diesel_platform` 产品仓：违反分层与源码仓纯净，且下游全部拖大。

Rejected:
- 把 MVS 二进制提交进任何**产品源码仓**；
- 把传输层插件提交进 `mvs-sdk`（体积大且与官方安装包重复）；
- 公开托管 MVS 二进制（违反海康许可与组织合规）。


---

## Decision

Date: 2026-11-12

Context: `.repos` 此前只 pin 了两个厂商 SDK。上游 ROS 包（`pb2025_*`、`rmoss_*`、
`sdformat_tools`、`small_gicp`）没有入账，而本地 `diesel_ws` 里已经有一棵**跑通过**
仿真链的树（`diesel_simulation` PR #6 / #7 的验收回执出自这棵树）。不记下来，
这棵树只能靠 detached HEAD 考古；M2「可复现基线」也无法验收。

Decision: 把 7 个上游 ROS 包写进 `src/`、`small_gicp` 写进 `third_party/`，
**commit 取自该沙箱的实测 HEAD**（不是上游最新）。新增 `scripts/check_repos_drift.sh`，
按 **URL** 比对工作区实际 commit 与 `.repos`。自研仓 `diesel_localization` 暂不入账，留 M4。

Reason:
- pin 的依据必须是「跑通过的那一份」：换到上游最新等于把已验证基线换成未验证基线
- 按 URL 比对而非路径：沙箱把 `small_gicp` 放 `deps/`，本仓规范是 `third_party/`，
  同一 commit 换个挂载目录不构成漂移，路径比对会制造假阳性
- 自研仓的 pin 必须指向 `dev` 的 commit；`diesel_localization` 的实现此刻还在未合分支
  （PR #10），pin 过去等于把未评审代码写进基线

Alternatives:
- 等 M2 正式启动再一次性整理 —— 沙箱是当前唯一证据来源，删了或重装即永久丢失
- 只记 URL 不记 commit —— vcstool 的 `version` 字段必填，不可行

Rejected:
- 用分支名（`dev`/`main`）替代 commit —— 违反 §5.1「pin commit，不用分支」

Consequences:
- `vcs import src < .repos` 可重建等价树；漂移由脚本兜底（负向自检：改一个 pin → exit 1）
- `mvs_sdk` 是私有仓，重建需要 GitHub 凭据；未导入时脚本报「未导入」而非漂移
- 沙箱里多出来的 `diesel_localization` 会被报「未入账」，这是 M4 之前的预期状态

## Decision

Date: 2026-11-12

Context: 宿主从容器改为直接部署 ROS 2 后，编译本来依赖一个临时沙箱目录（旧 `diesel_ws`），
而那棵树不在任何仓库里：删掉它，`diesel_simulation` 的 launch 立刻报
`package 'point_lio' not found`。把沙箱的依赖清单搬进本仓 `.repos` 后，重建仍连续踩两个坑：
`vcs import` 不跟进上游包的 submodule；`small_gicp_relocalization` 找不到 `small_gicp`
就 `FetchContent` 去 GitHub 拉 **master**（浮动，离线直接失败）。

Decision: 构建根就是本仓本身。`scripts/import_repos.sh` 导入后自动对带 `.gitmodules`
的上游仓执行 `git submodule update --init --recursive`；`scripts/colcon_build.sh` 先把
`.repos` pin 住的 `third_party/small_gicp` 装进 `third_party_install/`，再用
`FETCHCONTENT_SOURCE_DIR_SMALL_GICP` + `CMAKE_DISABLE_FIND_PACKAGE_small_gicp` 让
`small_gicp_relocalization` 走本地源码。宿主缺系统依赖时用
`DIESEL_SKIP_PACKAGES` 显式跳过个别包，不写死 skip 列表。

Reason:
- 沙箱不可复现：它的二进制来自容器时代，源码树又不在版本控制里，任何文档都无法重建
- submodule 是上游包自己的 pin，本仓 `.repos` 只管到父仓 commit，不补这一层就等于
  缺了 `point_lio` 等 7 个包——这是「pin 了却编不出」的假闭环
- `FetchContent` 的 `GIT_TAG master` 违反 §5.1「pin commit，不用分支」，必须绕开
- 上游 CMake 认裸目标名 `small_gicp`，pin 住的 small_gicp 导出 `small_gicp::small_gicp`；
  让 `find_package` 命中只会得到 `-lsmall_gicp` 而丢 include，因此固定走 FetchContent

Alternatives:
- 把 7 个 submodule 也写进 `.repos` —— 它们嵌在父仓目录内，会让 `vcs import` 与父仓
  checkout 打架；上游已经用 submodule pin 住，跟随即可
- 用 `--packages-skip` 写死在脚本里 —— 宿主差异被固化进仓库，别人换了机器反而编不全

Rejected:
- 继续依赖外部沙箱目录 —— 用户已要求清理，且它不是仓库、不可复现
- 关掉 `small_gicp_relocalization` —— 它是重定位链路的一部分，砍掉等于砍需求

Consequences:
- `scripts/import_repos.sh` 会多花约 1.5 min 拉 submodule；离线环境需要预置
- `image_common`（提供 `camera_info_manager`）也在同一次改动里入账：它不在 ROS 2 base
  安装里，`rmoss_cam` 一缺就编不出，宿主又没有 sudo 装 apt 包；按源码 pin 后
  `scripts/colcon_build.sh` 在无 sudo 的机器上也能全量通过（实测 38 个包）
- 全量 `scripts/colcon_build.sh` 在宿主实测 31 个包通过（跳过 `rmoss_cam`/`rmoss_gz_cam`）
- 起链回执：`ready=PASS ready_delay_s=0.94 lidar_s=0.09 localization_s=0.94
  bt_navigator=active controller_server=active last_state=OK`
- **已知未决**：同一棵树里 `accept.py a2` 的 `max_xy_err` 为 4.7~6.2 m（yaw 27°~120°），
  配准无「无有效对应」、退化仅 2/6 级、`lost=0`，与 M11 时的 0.039 m 不符，
  怀疑与点云/物理参数（新编 `rmoss_gz_plugins`/`point_lio`）或 truth 帧对齐有关，待查
