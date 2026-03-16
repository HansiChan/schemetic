# Schemetic — Flink SQL on Paimon (K8s)

基于 PyFlink + Paimon 的流式 SQL 数据管道，打包为 Docker 镜像并通过 Flink Kubernetes Operator 部署。

---

## 目录

- [前置条件](#前置条件)
- [仓库结构](#仓库结构)
- [快速开始](#快速开始)
  - [1. 克隆仓库](#1-克隆仓库)
  - [2. 下载 Flink 插件 JAR](#2-下载-flink-插件-jar)
  - [3. 编写 SQL 管道](#3-编写-sql-管道)
  - [4. 配置构建环境](#4-配置构建环境)
  - [5. 构建 Docker 镜像](#5-构建-docker-镜像)
  - [6. 推送镜像](#6-推送镜像)
  - [7. 配置 Kubernetes](#7-配置-kubernetes)
  - [8. 部署到 Kubernetes](#8-部署到-kubernetes)
- [镜像变体说明](#镜像变体说明)
- [CA 证书处理](#ca-证书处理)
- [自定义配置](#自定义配置)
- [卸载 / 清理](#卸载--清理)
- [常见问题排查](#常见问题排查)

---

## 前置条件

| 工具 | 用途 |
|---|---|
| **Docker** | 构建与推送镜像 |
| **GNU Make** | 自动化构建/部署 |
| **kubectl** | 已配置好的 K8s 集群访问 |
| **envsubst** (gettext) | K8s 清单模板渲染 |
| **Flink K8s Operator** | 集群中已安装 Flink CRD 和 Operator |

---

## 仓库结构

```
schemetic/
├── VERSION                          # 镜像版本号
├── Makefile                         # 项目脚手架 (create.project.*)
├── src/
│   ├── app.py                       # PyFlink 入口程序
│   └── sql/
│       ├── pipeline.sql             # 主 SQL 管道 (会被打包进镜像)
│       └── eWallet/                 # 按业务域组织的 SQL 脚本
├── flink-plugins/
│   ├── download-plugins.sh          # 一键下载所有 JAR 依赖
│   └── *.jar                        # Flink/Paimon/Hadoop JAR (gitignored)
├── docker/
│   ├── make.env/
│   │   ├── common.env               # 构建公共变量 (镜像仓库、项目名等)
│   │   └── common.local.env         # 本地覆盖 (gitignored, 需手动创建)
│   └── build/
│       ├── dev/                     # Debian 基础镜像构建
│       ├── amazone/                 # Amazon Linux 2023 基础镜像构建
│       │   ├── Dockerfile           # 标准版 (单阶段)
│       │   ├── Dockerfile.slim      # 精简版 (三阶段, 推荐生产用)
│       │   ├── Makefile
│       │   ├── requirements.txt     # Python 依赖
│       │   └── minio-ca.crt         # MinIO CA 证书
│       └── shared/                  # 构建公共逻辑
├── k8s/
│   ├── app.yaml                     # FlinkDeployment 模板
│   ├── Makefile                     # K8s 部署自动化
│   ├── .env                         # K8s 部署变量
│   └── env/
│       ├── config.env               # 非敏感环境变量 (gitignored)
│       └── secret.env               # 敏感环境变量 (gitignored)
└── argo/                            # ArgoCD / Kustomize 配置
```

---

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/<your-org>/schemetic.git
cd schemetic
```

### 2. 下载 Flink 插件 JAR

`flink-plugins/` 目录中的 JAR 文件被 `.gitignore` 排除，首次使用需要下载：

```bash
cd flink-plugins
bash download-plugins.sh
cd ..
```

脚本会自动从 Maven Central 下载以下组件（已有的 JAR 会自动跳过）：

| 组件 | 说明 |
|---|---|
| `flink-python-1.20.2.jar` | PyFlink 驱动 |
| `flink-s3-fs-hadoop-1.20.2.jar` | S3 文件系统支持 |
| `flink-table-*` | Flink Table/SQL 引擎 |
| `flink-connector-datagen` | DataGen 测试源 |
| `paimon-flink-1.20-1.3.1.jar` | Paimon Flink 连接器 |
| `paimon-s3-1.3.1.jar` | Paimon S3 存储支持 |
| `hadoop-*.jar` | Hadoop 依赖 (HDFS、MapReduce) |

### 3. 编写 SQL 管道

编辑 `src/sql/pipeline.sql`，这是会被打包进 Docker 镜像的主 SQL 文件。SQL 中支持 `${变量}` 模板语法，运行时由 `app.py` 替换：

| 变量 | 来源 | 说明 |
|---|---|---|
| `${CATALOG}` | 环境变量 `PAIMON_CATALOG` | Paimon Catalog 名称 |
| `${WAREHOUSE}` | 环境变量 `PAIMON_WAREHOUSE` | Paimon Warehouse 路径 |
| `${S3_ENDPOINT}` | 环境变量 `S3_ENDPOINT` | S3/MinIO 端点 |
| `${S3_ACCESS_KEY}` | 环境变量 `S3_ACCESS_KEY` | S3 Access Key |
| `${S3_SECRET_KEY}` | 环境变量 `S3_SECRET_KEY` | S3 Secret Key |
| `${S3_PATH_STYLE}` | 环境变量 `S3_PATH_STYLE` | 路径风格访问 (`true`/`false`) |
| `${DATABASE}` | 环境变量 `PAIMON_DATABASE` | 默认数据库名 |

> **多条 INSERT**: `app.py` 会自动将多条 `INSERT INTO` 语句合并到 `StatementSet` 中作为单个 Flink Job 执行。

### 4. 配置构建环境

#### 4.1 编辑公共变量

编辑 `docker/make.env/common.env`：

```env
# 修改为你的镜像仓库
IMAGE_REPO_ROOT=quay.io/<your-org>
PROJECT_NAME=flink
APP_NAME=base
```

#### 4.2 设置版本号

```bash
echo "0.1.0" > VERSION
```

#### 4.3 创建本地覆盖文件 (可选)

```bash
cp docker/make.env/common.local.env.example docker/make.env/common.local.env
# 编辑 common.local.env 覆盖任何需要本地化的值
```

#### 4.4 如果使用自定义 CA（如自签 MinIO）

将你的 CA 证书放置到对应的构建目录：

```bash
cp /path/to/your-ca.crt docker/build/amazone/minio-ca.crt
```

### 5. 构建 Docker 镜像

项目提供了多种 Dockerfile，推荐使用 **amazone slim** 版本（Amazon Linux 2023 三阶段构建，最小化镜像体积）：

```bash
# 方式 A: 使用 Make (推荐)
cd docker/build/amazone
make build.app DOCKERFILE=$(pwd)/Dockerfile.slim

# 方式 B: 直接使用 Docker (从仓库根目录)
docker build --platform linux/amd64 \
  -f docker/build/amazone/Dockerfile.slim \
  --build-arg PYTHON_VERSION=3.11 \
  --build-arg UV_VERSION=v0.4.20 \
  -t quay.io/<your-org>/flink_base:0.1.0-amazone-slim \
  .
```

> 镜像 Tag 默认格式: `{IMAGE_REPO_ROOT}/{PROJECT_NAME}_{APP_NAME}:{VERSION}-amazone.{BUILD_NUMBER}`

### 6. 推送镜像

```bash
# 方式 A: Make
cd docker/build/amazone
make push.app

# 方式 B: Docker
docker push quay.io/<your-org>/flink_base:0.1.0-amazone-slim
```

### 7. 配置 Kubernetes

#### 7.1 编辑部署变量

编辑 `k8s/.env`：

```env
# 镜像信息 (改为你实际推送的镜像)
IMAGE_REPO_ROOT=quay.io/<your-org>
DEV_IMAGE_NAME=flink_base
DEV_IMAGE_TAG=0.1.0-amazone-slim
DEV_IMAGE=${IMAGE_REPO_ROOT}/${DEV_IMAGE_NAME}:${DEV_IMAGE_TAG}

# K8s 配置
NAME=ewallet-dwd-pipeline        # FlinkDeployment 名称
NAMESPACE=flink                   # K8s 命名空间
SERVICE_ACCOUNT=flink             # K8s ServiceAccount

# Flink 配置
FLINK_VERSION=v1_20
FLINK_DEPLOY_MODE=native
```

#### 7.2 创建环境变量文件

**非敏感变量** — `k8s/env/config.env`：

```env
PAIMON_WAREHOUSE=s3a://prd-datalake/
PAIMON_CATALOG=paimon_catalog
PAIMON_DATABASE=dwd
S3_ENDPOINT=https://minio.example.com
S3_PATH_STYLE=true
SQL_FILE=/opt/flink/sql/pipeline.sql
PIPELINE_NAME=ewallet-ods-to-dwd
CHECKPOINT_INTERVAL=10 s
```

**敏感变量** — `k8s/env/secret.env`：

```env
S3_ACCESS_KEY=<your-access-key>
S3_SECRET_KEY=<your-secret-key>
```

> ⚠️ `secret.env` 已被 `.gitignore` 排除，请勿提交到 Git。

#### 7.3 确认 PVC

确保目标命名空间中存在名为 `flink-data` 的 PersistentVolumeClaim，用于 Checkpoint 和 Savepoint 存储。

### 8. 部署到 Kubernetes

```bash
cd k8s

# 一键部署 (自动创建 namespace、ConfigMap、Secret 并 apply FlinkDeployment)
make up

# 或逐步执行：
make ns            # 创建命名空间
make env.up        # 创建/更新 ConfigMap (非敏感变量)
make secret.up     # 创建/更新 Secret (敏感变量)
```

检查部署状态：

```bash
make status                                      # 查看 Pod 状态
kubectl logs -n flink <jobmanager-pod> -f         # 查看 JobManager 日志
kubectl logs -n flink <taskmanager-pod> -f        # 查看 TaskManager 日志
```

---

## 镜像变体说明

| 路径 | 基础镜像 | 构建方式 | 适用场景 |
|---|---|---|---|
| `docker/build/dev/Dockerfile` | `flink:1.20.1-scala_2.12` (Debian) | 单阶段 | 开发调试 |
| `docker/build/amazone/Dockerfile` | Amazon Linux 2023 | 单阶段 | EKS / 简单部署 |
| `docker/build/amazone/Dockerfile.slim` | Amazon Linux 2023 | **三阶段** | **生产推荐** (最小镜像) |

Slim 版通过三阶段构建丢弃 gcc/make 等编译工具，只保留运行时依赖，镜像体积显著更小。

---

## CA 证书处理

如果你的对象存储 (MinIO) 使用自签 CA 证书：

1. 证书已在构建时通过 `register-ca.sh` 导入到 Java truststore (`/etc/ssl/truststore/cacerts`)
2. 运行时通过 `JAVA_TOOL_OPTIONS` 环境变量指定 truststore 路径
3. 无需 initContainer，证书已 bake 进镜像

如需更换 CA 证书，替换 `docker/build/amazone/minio-ca.crt` 后重新构建镜像。

---

## 自定义配置

| 需求 | 操作 |
|---|---|
| 修改 Flink 资源 (CPU/内存) | 编辑 `k8s/app.yaml` 中的 `jobManager` / `taskManager` |
| 调整并行度 | 编辑 `k8s/app.yaml` 中 `job.parallelism` |
| 修改 Checkpoint 间隔 | 编辑 `k8s/env/config.env` 中 `CHECKPOINT_INTERVAL` |
| 添加 Python 依赖 | 编辑 `docker/build/amazone/requirements.txt`，重新构建镜像 |
| 更新 Flink/Paimon 版本 | 编辑 `flink-plugins/download-plugins.sh` 中的版本号，重新下载并构建 |
| 通过 ConfigMap 挂载 SQL | 参考 `k8s/SQL_CONFIGMAP_GUIDE.md`，无需重新构建镜像 |

---

## 卸载 / 清理

```bash
# 删除 K8s 资源
cd k8s
make down

# 清理本地 Docker 镜像
cd docker
make clean
```

---

## 常见问题排查

| 问题 | 排查方向 |
|---|---|
| JAR 下载失败 | 检查网络是否能访问 Maven Central，或手动下载放入 `flink-plugins/` |
| `envsubst` 未找到 | 安装 gettext: `brew install gettext` (macOS) 或 `apt install gettext` (Linux) |
| CA/SSL 错误 | 确认 `minio-ca.crt` 是否正确，检查 `JAVA_TOOL_OPTIONS` 是否在 Pod 中生效 |
| `NoClassDefFoundError` | 检查 `flink-plugins/` 中是否缺少对应 JAR，重新运行 `download-plugins.sh` |
| Pod CrashLoopBackOff | 检查 JM 日志：`kubectl logs -n flink <pod>` |
| SQL 语法错误 | 在 `pipeline.sql` 中调试，确保 `${变量}` 模板语法正确 |
| 多 INSERT 未执行 | `app.py` 使用 `StatementSet` 合并多条 INSERT，检查日志确认所有语句是否被正确解析 |
