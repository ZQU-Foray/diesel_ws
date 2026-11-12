# 开发计划

## 任务列表

- [x] 写 `.repos` 骨架（先 pin 第三方上游包）
  - 已 pin Livox-SDK2 v1.3.1（commit `f5d9375f`）
  - 已 pin 海康 MVS SDK（私有仓 `ZQU-Foray/mvs-sdk`；commit `b55df46`，SDK 4.8.0.3，
    `decision.md` 2026-10-23 条目记的是首次 pin 的 `353b584`/V4.1.2.2，之后前进过两次）
  - 2026-11-12 补入 7 个上游 ROS 包 + `small_gicp`，commit 取自
    临时沙箱（原 `foray_sim_ws`，2026-11-12 已删除）里跑通过仿真链的那棵树（不是上游最新），依据见 `decision.md`
- [x] 本仓即构建根：`vcs import --input .repos .` 后 `scripts/colcon_build.sh`
  - 2026-11-12 起宿主直接用本仓 build/install，不再依赖临时沙箱（已于 2026-11-12 删除）
  - 实测：`scripts/colcon_build.sh` 38 个包通过（含 `camera_info_manager` 源码入账）；
    `ros2 launch diesel_simulation_bringup navigation_sim.launch.py` 起 link 正常，
    `accept.py ready` → `ready=PASS lidar_s=0.10 localization_s=0.94`
  - 未跑全量是因为宿主无 sudo，缺 `camera_info_manager`（`rmoss_cam` 需要），
    临时 `--packages-skip rmoss_cam rmoss_gz_cam`；补 `rosdep install` 后应恢复全量
- [ ] 把当前 `diesel_navigation` fork 也作为 pin 项（M3）
- [ ] 搭集成 CI（按 `.repos` 拉全量 → 全量 build）
- [x] 写一键脚本（拉取 / 构建；启动待装配根）
- [x] 命名门禁 `scripts/check_naming.sh`（Diesel 迁移，CI `naming` 作业）
  - 白名单逐条给理由：org 名、`foray_docs`、fork 后缀、战队文案/版权头、下位机两仓、
    门户仓、教学仓，以及 P4 改名前仍需引用的 `foray_localization`
  - 2026-11-12 实跑：11 个上位机仓全部「白名单外无旧命名残留」；
    首跑抓到 `scripts/build_livox_sdk2.sh` 的 `~/.cache/foray-build` 两处真残留并已修
  - 同日发现门禁本身是空壳（白名单赋值丢失 ⇒ `grep -Ev ""` 放行一切），已修复并加
    CI 负向自检；修复后逐仓复跑仍是 11 仓 exit 0，见 `decision.md` 2026-11-12 条目
- [ ] 打第一个整机 tag（M6）

## 当前 Agent State

LIVOX_SDK_PINNED + MVS_SDK_PINNED + UPSTREAM_PINNED

## Before Snapshot

commit hash:   6f0fd98
branch:        dev
modified files: `.repos`、`.gitignore`、`README.md`、`VERSIONS.md`、`decision.md`、`plan.md`、`tree.md`；新增 `third_party/COLCON_IGNORE` 与 `scripts/`
risk level:    L1

## 模糊点与待确认项

- 本仓接口尚未冻结，任务清单为**方向性**的，落地顺序以 `foray_docs/algorithm_structure.md` §9 演进阶段为准
- 依赖的自研仓尚未建齐，跨仓任务需等对方 `README.md` 明确接口后再启动
- Livox SDK2 开发机默认装到 `~/.cache/diesel-platform-prefix/livox-sdk2`；
  实机镜像固定 `/opt/diesel/livox-sdk2`（通过 `DIESEL_LIVOX_SDK2_PREFIX` 覆盖）
- 已删除的临时沙箱把 `small_gicp` 放在 `deps/`（本仓规范是 `third_party/`）；
  两者 commit 相同，漂移检查按 URL 比对，不把路径差异当漂移
- 自研仓 `diesel_localization` 尚未入账：它的 pin 必须指向 `dev` 的 commit，
  而实现还在未合分支上（diesel_localization PR #10），M4 再收
- 海康 MVS SDK 开发机默认装到 `~/.cache/diesel-platform-prefix/mvs-sdk`；
  实机镜像固定 `/opt/diesel/mvs-sdk`（通过 `DIESEL_MVS_PREFIX` 覆盖）。
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
- [x] `.repos` pin 住上游 ROS 包与 `small_gicp`（沙箱实测 commit）
- [x] `scripts/check_repos_drift.sh` 能识别 commit 漂移（负向自检：改一个 pin → exit 1）
- [ ] 本仓能独立 `colcon build`（无代码时跳过）
- [ ] CI 绿灯
- [ ] 每个新增模块带独立可执行测试
