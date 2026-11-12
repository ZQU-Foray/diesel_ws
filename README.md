# foray_ws

> **META** · owner 角色：架构

元仓：.repos 锁定 + 集成 CI + 一键拉取/构建/启动

**零业务代码。** 整机 tag = 可复现的「那一台能跑的车」。

---

## 快速开始

> 本仓处于**初始化状态**：Livox SDK2 与海康 MVS SDK 已在 `.repos` 中 pin，
> 自研仓待接口冻结后加入。
> 以下流程随 P0/P1 落地逐步可用。

```bash
# 1. 拉取本仓
git clone git@github.com:ZQU-Foray/foray_ws.git
cd foray_ws

# 2. 加载环境并拉取依赖（SDK 落在 third_party/，不进 src/）
source scripts/env.sh
scripts/import_repos.sh

# 3. 构建 Livox SDK2（需要真实雷达驱动时）
scripts/build_livox_sdk2.sh

# 4. 安装海康 MVS SDK（需要真实相机驱动时）
#    官方安装包需自行从海康官网下载；--package 用于补齐传输层插件
scripts/install_mvs_sdk.sh --package /path/to/MVS_Linux_*.tar.gz

# 5. ROS 依赖安装（src/ 有自研仓后）
if [ -d src ]; then
  rosdep install -y -r --from-paths src --ignore-src --rosdistro humble
fi

# 6. 构建：默认驱动 stub；实机加 FORAY_LIVOX_SDK=ON
scripts/colcon_build.sh
FORAY_LIVOX_SDK=ON scripts/colcon_build.sh

# 7. 运行
# （待装配根就绪后补充）
```

实机 SDK 前缀：Livox `/opt/foray/livox-sdk2`，MVS `/opt/foray/mvs-sdk`：

```bash
FORAY_LIVOX_SDK2_PREFIX=/opt/foray/livox-sdk2 source scripts/env.sh
FORAY_MVS_PREFIX=/opt/foray/mvs-sdk source scripts/env.sh
```

## 依赖

| 类型 | 依赖 |
|---|---|
| **自研仓** | 接口冻结后逐项写入 `.repos` |
| **第三方** | vcstool · colcon · rosdep · Livox-SDK2（v1.3.1，pin commit）· MVS SDK（V4.1.2.2，私有仓 pin commit） |

## 接口

| 产出 | 内容 |
|---|---|
| `.repos` | 全部依赖清单，**pin commit** |
| `VERSIONS.md` | 当前整机 tag 包含的各仓 commit |
| 集成 CI | 按 `.repos` 拉全量 → 全量 build → 集成测试 |
| 一键脚本 | 拉取 / 构建 / 启动 |

## 版本锁定：三层机制



| 层 | 机制 |

|---|---|

| 仓级 | 语义化版本 + tag（接口仓尤其严格） |

| 引用级 | 本仓 `.repos` **pin commit**（**不用分支**，不用「大概最新」） |

| 整机级 | **本仓 meta tag**，如 `sentry-2026-regional-v1.0.0` |



## 为什么用 vcstool 而不是 git submodule



| 方案 | 评价 |

|---|---|

| `git submodule` | 原生，但操作繁琐易错（子模块未初始化是新人第一大坑） |

| **`vcstool` + `.repos`** ✅ | SMBU 与 RMOSS 生态均采用；对新手友好；一文件描述全部依赖 |



## 纪律



- **零业务代码**——本仓不出现任何算法实现

- `.repos` 变更**必须说明换版本理由**（评审追加要求）

- 排障第一步：**确认场上跑的是哪个整机 tag**



## 当前阶段



M1（`foray_interfaces` 最小契约集）尚未完成；`.repos` 已启用并 pin 了
Livox-SDK2 v1.3.1 与海康 MVS SDK V4.1.2.2，自研仓仍待接口冻结后逐项加入。

见 `foray_docs/repository_structure.md` §8 迁移路径。

## 上下游

| 方向 | 对象 |
|---|---|
| **上游**（本仓依赖谁） | 全组织所有仓（以 pin commit 引用） |
| **下游**（谁依赖本仓） | 无（顶层） |

## 参考

- [算法结构](https://github.com/ZQU-Foray/foray_docs/blob/main/algorithm_structure.md)
- [仓库结构](https://github.com/ZQU-Foray/foray_docs/blob/main/repository_structure.md)
- [组织贡献指南](https://github.com/ZQU-Foray/.github/blob/main/CONTRIBUTING.md)
