# 目录结构说明

## 目录结构

```
.
├── README.md                本仓定位、接口、上下游
├── AGENTS.md                AI 协作规范
├── plan.md                  开发计划与进度
├── decision.md              关键工程决策日志
├── tree.md                  本文件
├── CODEOWNERS               Review 自动分派
├── .diesel-layer             所属层与依赖边界（CI 校验）
├── .repos                   依赖清单（vcstool，pin commit）
├── VERSIONS.md              整机 tag 与第三方 pin
├── .gitignore
├── scripts/
│   ├── env.sh               环境变量（LIVOX_SDK2_ROOT / MVS_ROOT / LD_LIBRARY_PATH）
│   ├── import_repos.sh      按 .repos 拉取依赖
│   ├── check_repos_drift.sh 比对工作区实际 commit 与 .repos（按 URL）
│   ├── check_naming.sh      命名门禁：白名单外不得残留 foray（Diesel 迁移）
│   ├── build_livox_sdk2.sh  构建/安装 Livox SDK2
│   ├── install_mvs_sdk.sh   安装海康 MVS SDK（可选补齐传输层插件）
│   └── colcon_build.sh      固定 --base-paths src 的构建入口
├── third_party/
│   ├── COLCON_IGNORE        阻止 colcon 递归发现
│   ├── livox_sdk2/          vcstool 拉取，不入库
│   └── mvs_sdk/             vcstool 拉取（私有仓），不入库
└── .github/
    └── workflows/
        └── ci.yml           复制自组织 CI 模板
```

> 本仓为**初始化状态**：两个厂商 SDK 与 7 个上游 ROS 包 + `small_gicp` 已 pin；
> 自研仓待接口冻结后加入 `src/`（M4）。

## 记录约束

MUST NOT 记录以下内容：

- `build/`、`install/`、`log/`、`.git/` 等依赖与产物目录
- 临时文件、缓存文件、日志文件
