# 版本清单

> 记录当前**整机 tag** 所包含的各仓 commit。
> 排障第一步就是确认场上跑的是哪个 tag。

## 当前

- 整机 tag：尚未产生（M6）。
- 第三方 pin：见下表，完整清单以 `.repos` 为准（2026-11-12 补入 7 个上游 ROS 包 + `small_gicp`）。

| 依赖 | commit | 说明 |
|---|---|---|
| Livox-SDK2 | `f5d9375f84efe2b15bc0a052d3e18482ed13adf4` | v1.3.1；由 `scripts/build_livox_sdk2.sh` 构建安装 |
| MVS SDK（海康） | `b55df46b6dbbf20a21afe6885c2125620aa6209a` | 4.8.0.3（Build 20260512）；私有仓 `ZQU-Foray/mvs-sdk`，由 `scripts/install_mvs_sdk.sh` 安装 |
| `pb2025_sentry_nav` | `5f645d60e8cb88440f0bb44fc63209f136a95a49` | 上游 fork 基线（含 point_lio） |
| `pb2025_robot_description` | `a0541dddcbfe376f369a6345b532a10923ad9149` | pb2025 步兵 / 哨兵 xmacro |
| `rmoss_core` | `8209ec517dfbb7ecac613cf0c9534d67ff918b7d` | RMOSS 基础设施 |
| `rmoss_gazebo` | `7443ff06c345752d0e23172c479d99b27207e2c7` | Gazebo 插件与实体 |
| `rmoss_gz_resources` | `b5c759f08844dfda19c79aa870866ace8d4c7b3a` | 场地 / 机器人资源 |
| `rmoss_interfaces` | `424f50c831b3e74fa72446969362cdabb2e22cd1` | RMOSS 消息与服务 |
| `sdformat_tools` | `47c2d1a37372281e5627d444f7537efc0bba11df` | SDF 转换工具 |
| `small_gicp` | `fa0cfc983417c044b6036f71dfa448038bb9c820` | 纯头文件 GICP，供 `pb2025_sentry_nav` 取用 |
| `image_common` | `28775054b0f85565f2a0213d2ab8a965e848dc5b` | `camera_info_manager`，供 `rmoss_cam` 取用 |

## 格式（首个 tag 后）

## sentry-2026-regional-v1.0.0

| 仓 | commit | 说明 |
|---|---|---|
| `diesel_interfaces` | `<sha>` | |
| `diesel_platform` | `<sha>` | |
| `diesel_localization` | `<sha>` | |
| `diesel_vision` | `<sha>` | |
| `diesel_auto_aim` | `<sha>` | |
| `diesel_navigation` | `<sha>` | |
| `diesel_decision` | `<sha>` | |
| `diesel_robots` | `<sha>` | |
| 第三方 | 见 `.repos` | |
