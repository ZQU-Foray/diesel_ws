# 版本清单

> 记录当前**整机 tag** 所包含的各仓 commit。
> 排障第一步就是确认场上跑的是哪个 tag。

## 当前

- 整机 tag：尚未产生（M6）。
- 第三方 pin：见下表，完整清单以 `.repos` 为准。

| 依赖 | commit | 说明 |
|---|---|---|
| Livox-SDK2 | `f5d9375f84efe2b15bc0a052d3e18482ed13adf4` | v1.3.1；由 `scripts/build_livox_sdk2.sh` 构建安装 |
| MVS SDK（海康） | `353b584614f42fc286b9f684735f6479401e63d6` | V4.1.2.2；私有仓 `ZQU-Foray/mvs-sdk`，由 `scripts/install_mvs_sdk.sh` 安装 |

## 格式（首个 tag 后）

## sentry-2026-regional-v1.0.0

| 仓 | commit | 说明 |
|---|---|---|
| `foray_interfaces` | `<sha>` | |
| `foray_platform` | `<sha>` | |
| `foray_localization` | `<sha>` | |
| `foray_vision` | `<sha>` | |
| `foray_auto_aim` | `<sha>` | |
| `foray_navigation` | `<sha>` | |
| `foray_decision` | `<sha>` | |
| `foray_robots` | `<sha>` | |
| 第三方 | 见 `.repos` | |
