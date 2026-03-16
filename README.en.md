# Schemetic — Flink SQL on Paimon

A streaming SQL data pipeline built with PyFlink + Apache Paimon, packaged as a Docker image for Kubernetes deployment via the Flink K8s Operator.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Repository Layout](#repository-layout)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Download Flink Plugin JARs](#2-download-flink-plugin-jars)
  - [3. Write Your SQL Pipeline](#3-write-your-sql-pipeline)
  - [4. Configure the Build Environment](#4-configure-the-build-environment)
  - [5. Build the Docker Image](#5-build-the-docker-image)
  - [6. Push the Image](#6-push-the-image)
- [Image Variants](#image-variants)
- [CA Certificate Handling](#ca-certificate-handling)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool | Purpose |
|---|---|
| **Docker** | Build and push images |
| **GNU Make** | Build automation |
| **curl** | Download plugin JARs |

---

## Repository Layout

```
schemetic/
├── VERSION                          # Image version number
├── src/
│   ├── app.py                       # PyFlink entry program
│   └── sql/
│       ├── pipeline.sql             # Main SQL pipeline (bundled into image)
│       └── eWallet/                 # Business-domain SQL scripts
├── flink-plugins/
│   ├── download-plugins.sh          # One-click JAR download script
│   └── *.jar                        # Flink/Paimon/Hadoop JARs (gitignored)
├── docker/
│   ├── make.env/
│   │   ├── common.env               # Shared build variables
│   │   └── common.local.env         # Local overrides (gitignored)
│   └── build/
│       ├── dev/                     # Debian-based build
│       └── amazone/                 # Amazon Linux 2023 build
│           ├── Dockerfile           # Standard (single-stage)
│           ├── Dockerfile.slim      # Slim (multi-stage, recommended)
│           ├── Makefile
│           ├── requirements.txt     # Python dependencies
│           └── minio-ca.crt         # MinIO CA certificate
└── k8s/                             # Kubernetes deployment manifests
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/<your-org>/schemetic.git
cd schemetic
```

### 2. Download Flink Plugin JARs

JAR files under `flink-plugins/` are excluded by `.gitignore`. Run the download script on first use:

```bash
cd flink-plugins
bash download-plugins.sh
cd ..
```

The script downloads the following from Maven Central (existing JARs are skipped automatically):

| Component | Description |
|---|---|
| `flink-python-1.20.2.jar` | PyFlink driver |
| `flink-s3-fs-hadoop-1.20.2.jar` | S3 filesystem support |
| `flink-table-*` | Flink Table/SQL engine |
| `flink-connector-datagen` | DataGen test source |
| `paimon-flink-1.20-1.3.1.jar` | Paimon Flink connector |
| `paimon-s3-1.3.1.jar` | Paimon S3 storage support |
| `hadoop-*.jar` | Hadoop dependencies (HDFS, MapReduce) |

### 3. Write Your SQL Pipeline

Edit `src/sql/pipeline.sql` — this is the main SQL file bundled into the Docker image. Template variables using `${VAR}` syntax are substituted at runtime by `app.py`:

| Variable | Source Env Var | Description |
|---|---|---|
| `${CATALOG}` | `PAIMON_CATALOG` | Paimon Catalog name |
| `${WAREHOUSE}` | `PAIMON_WAREHOUSE` | Paimon Warehouse path |
| `${S3_ENDPOINT}` | `S3_ENDPOINT` | S3/MinIO endpoint |
| `${S3_ACCESS_KEY}` | `S3_ACCESS_KEY` | S3 Access Key |
| `${S3_SECRET_KEY}` | `S3_SECRET_KEY` | S3 Secret Key |
| `${S3_PATH_STYLE}` | `S3_PATH_STYLE` | Path-style access (`true`/`false`) |
| `${DATABASE}` | `PAIMON_DATABASE` | Default database name |

> **Multiple INSERTs**: `app.py` automatically merges multiple `INSERT INTO` statements into a single `StatementSet` and executes them as one Flink job.

### 4. Configure the Build Environment

#### 4.1 Edit Shared Variables

Edit `docker/make.env/common.env`:

```env
# Change to your image registry
IMAGE_REPO_ROOT=quay.io/<your-org>
PROJECT_NAME=flink
APP_NAME=base
```

#### 4.2 Set the Version

```bash
echo "0.1.0" > VERSION
```

#### 4.3 Create Local Overrides (Optional)

```bash
cp docker/make.env/common.local.env.example docker/make.env/common.local.env
# Edit common.local.env to override any values locally
```

#### 4.4 Custom CA Certificate (If Using Self-Signed MinIO)

Place your CA certificate in the build directory:

```bash
cp /path/to/your-ca.crt docker/build/amazone/minio-ca.crt
```

### 5. Build the Docker Image

The project provides multiple Dockerfiles. The **amazone slim** variant (Amazon Linux 2023, three-stage build) is recommended for production:

```bash
# Option A: Using Make (recommended)
# Default tag: quay.io/<your-org>/flink_base:amazone
cd docker/build/amazone
make build.app DOCKERFILE=$(pwd)/Dockerfile.slim

# To use a custom tag, pass IMAGE=:
make build.app DOCKERFILE=$(pwd)/Dockerfile.slim \
  IMAGE=quay.io/<your-org>/flink_base:0.1.0-amazone-slim

# Option B: Using Docker directly (from repo root)
docker build --platform linux/amd64 \
  -f docker/build/amazone/Dockerfile.slim \
  --build-arg PYTHON_VERSION=3.11 \
  --build-arg UV_VERSION=v0.4.20 \
  -t quay.io/<your-org>/flink_base:0.1.0-amazone-slim \
  .
```

> **Note on image tags**: When using `make build.app` without `IMAGE=`, the default tag is `{IMAGE_REPO_ROOT}/{PROJECT_NAME}_{APP_NAME}:amazone` (e.g., `quay.io/colinchan2025/flink_base:amazone`). The Dockerfile choice (standard vs slim) does **not** affect the tag — pass `IMAGE=` explicitly if you need a version-specific tag.

### 6. Push the Image

```bash
# Option A: Make (pushes the same tag used in build.app)
cd docker/build/amazone
make push.app
# Or with a custom tag:
make push.app IMAGE=quay.io/<your-org>/flink_base:0.1.0-amazone-slim

# Option B: Docker
docker push quay.io/<your-org>/flink_base:0.1.0-amazone-slim
```

---

## Image Variants

| Path | Base Flink Version | Base OS | Build Strategy | Use Case |
|---|---|---|---|---|
| `docker/build/dev/Dockerfile` | 1.20.1 | Debian (flink official) | Single-stage | Development / debugging |
| `docker/build/amazone/Dockerfile` | 1.20.2 | Amazon Linux 2023 | Single-stage | EKS / simple deployments |
| `docker/build/amazone/Dockerfile.slim` | 1.20.2 | Amazon Linux 2023 | **Three-stage** | **Production (smallest image)** |

The slim variant discards build tools (gcc, make) via multi-stage builds, keeping only runtime dependencies for a significantly smaller image.

---

## CA Certificate Handling

If your object store (e.g., MinIO) uses a self-signed CA certificate:

1. The certificate is imported into a Java truststore (`/etc/ssl/truststore/cacerts`) at build time via `register-ca.sh`
2. At runtime, `JAVA_TOOL_OPTIONS` points the JVM to the truststore
3. No initContainer is required — the certificate is baked into the image

To update the CA, replace `docker/build/amazone/minio-ca.crt` and rebuild.

---

## Customization

| Need | Action |
|---|---|
| Add Python dependencies | Edit `docker/build/amazone/requirements.txt`, rebuild image |
| Update Flink/Paimon version | Edit versions in `flink-plugins/download-plugins.sh`, re-download and rebuild |
| Change build platform | Set `--platform` flag or `DOCKER_PLATFORM` env var |

---

## Troubleshooting

| Issue | Resolution |
|---|---|
| JAR download failure | Check network access to Maven Central, or manually download JARs into `flink-plugins/` |
| `NoClassDefFoundError` | Missing JAR in `flink-plugins/` — re-run `download-plugins.sh` |
| CA/SSL errors | Verify `minio-ca.crt` is correct and rebuild the image |
| Build fails on ARM Mac | Ensure `--platform linux/amd64` is set (required for EKS/x86 clusters) |

---
---

# 中文对照版

# Schemetic — 基于 Paimon 的 Flink SQL 流处理

基于 PyFlink + Apache Paimon 的流式 SQL 数据管道，打包为 Docker 镜像，用于通过 Flink K8s Operator 部署到 Kubernetes。

---

## 目录

- [前置条件](#前置条件)
- [仓库结构](#仓库结构-1)
- [快速开始](#快速开始)
  - [1. 克隆仓库](#1-克隆仓库)
  - [2. 下载 Flink 插件 JAR](#2-下载-flink-插件-jar)
  - [3. 编写 SQL 管道](#3-编写-sql-管道)
  - [4. 配置构建环境](#4-配置构建环境)
  - [5. 构建 Docker 镜像](#5-构建-docker-镜像)
  - [6. 推送镜像](#6-推送镜像)
- [镜像变体说明](#镜像变体说明)
- [CA 证书处理](#ca-证书处理)
- [自定义配置](#自定义配置-1)
- [常见问题排查](#常见问题排查)

---

## 前置条件

| 工具 | 用途 |
|---|---|
| **Docker** | 构建与推送镜像 |
| **GNU Make** | 自动化构建 |
| **curl** | 下载插件 JAR |

---

## 仓库结构

```
schemetic/
├── VERSION                          # 镜像版本号
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
│   │   ├── common.env               # 构建公共变量
│   │   └── common.local.env         # 本地覆盖 (gitignored)
│   └── build/
│       ├── dev/                     # Debian 基础镜像构建
│       └── amazone/                 # Amazon Linux 2023 基础镜像构建
│           ├── Dockerfile           # 标准版 (单阶段)
│           ├── Dockerfile.slim      # 精简版 (三阶段, 推荐)
│           ├── Makefile
│           ├── requirements.txt     # Python 依赖
│           └── minio-ca.crt         # MinIO CA 证书
└── k8s/                             # Kubernetes 部署清单
```

---

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/<your-org>/schemetic.git
cd schemetic
```

### 2. 下载 Flink 插件 JAR

`flink-plugins/` 下的 JAR 文件被 `.gitignore` 排除，首次使用需运行下载脚本：

```bash
cd flink-plugins
bash download-plugins.sh
cd ..
```

脚本会自动从 Maven Central 下载以下组件（已存在的 JAR 会自动跳过）：

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

| 变量 | 来源环境变量 | 说明 |
|---|---|---|
| `${CATALOG}` | `PAIMON_CATALOG` | Paimon Catalog 名称 |
| `${WAREHOUSE}` | `PAIMON_WAREHOUSE` | Paimon Warehouse 路径 |
| `${S3_ENDPOINT}` | `S3_ENDPOINT` | S3/MinIO 端点 |
| `${S3_ACCESS_KEY}` | `S3_ACCESS_KEY` | S3 Access Key |
| `${S3_SECRET_KEY}` | `S3_SECRET_KEY` | S3 Secret Key |
| `${S3_PATH_STYLE}` | `S3_PATH_STYLE` | 路径风格访问 (`true`/`false`) |
| `${DATABASE}` | `PAIMON_DATABASE` | 默认数据库名 |

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

#### 4.4 自定义 CA 证书 (如使用自签 MinIO)

将你的 CA 证书放置到构建目录：

```bash
cp /path/to/your-ca.crt docker/build/amazone/minio-ca.crt
```

### 5. 构建 Docker 镜像

项目提供了多种 Dockerfile，推荐使用 **amazone slim** 版本（Amazon Linux 2023 三阶段构建，最小化镜像体积）：

```bash
# 方式 A: 使用 Make (推荐)
# 默认 tag: quay.io/<your-org>/flink_base:amazone
cd docker/build/amazone
make build.app DOCKERFILE=$(pwd)/Dockerfile.slim

# 指定自定义 tag，传入 IMAGE= 参数:
make build.app DOCKERFILE=$(pwd)/Dockerfile.slim \
  IMAGE=quay.io/<your-org>/flink_base:0.1.0-amazone-slim

# 方式 B: 直接使用 Docker (从仓库根目录)
docker build --platform linux/amd64 \
  -f docker/build/amazone/Dockerfile.slim \
  --build-arg PYTHON_VERSION=3.11 \
  --build-arg UV_VERSION=v0.4.20 \
  -t quay.io/<your-org>/flink_base:0.1.0-amazone-slim \
  .
```

> **关于镜像标签**: 使用 `make build.app` 且不传 `IMAGE=` 时，默认 tag 为 `{IMAGE_REPO_ROOT}/{PROJECT_NAME}_{APP_NAME}:amazone`（例如 `quay.io/colinchan2025/flink_base:amazone`）。选择不同的 Dockerfile（标准版 vs slim）**不会**自动改变 tag，如需带版本号的 tag 请通过 `IMAGE=` 显式指定。

### 6. 推送镜像

```bash
# 方式 A: Make (推送与 build.app 相同的 tag)
cd docker/build/amazone
make push.app
# 或指定自定义 tag:
make push.app IMAGE=quay.io/<your-org>/flink_base:0.1.0-amazone-slim

# 方式 B: Docker
docker push quay.io/<your-org>/flink_base:0.1.0-amazone-slim
```

---

## 镜像变体说明

| 路径 | Flink 版本 | 基础 OS | 构建方式 | 适用场景 |
|---|---|---|---|---|
| `docker/build/dev/Dockerfile` | 1.20.1 | Debian (flink 官方镜像) | 单阶段 | 开发调试 |
| `docker/build/amazone/Dockerfile` | 1.20.2 | Amazon Linux 2023 | 单阶段 | EKS / 简单部署 |
| `docker/build/amazone/Dockerfile.slim` | 1.20.2 | Amazon Linux 2023 | **三阶段** | **生产推荐 (最小镜像)** |

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
| 添加 Python 依赖 | 编辑 `docker/build/amazone/requirements.txt`，重新构建镜像 |
| 更新 Flink/Paimon 版本 | 编辑 `flink-plugins/download-plugins.sh` 中的版本号，重新下载并构建 |
| 修改构建平台 | 设置 `--platform` 参数或 `DOCKER_PLATFORM` 环境变量 |

---

## 常见问题排查

| 问题 | 排查方向 |
|---|---|
| JAR 下载失败 | 检查网络是否能访问 Maven Central，或手动下载放入 `flink-plugins/` |
| `NoClassDefFoundError` | 检查 `flink-plugins/` 中是否缺少对应 JAR，重新运行 `download-plugins.sh` |
| CA/SSL 错误 | 确认 `minio-ca.crt` 是否正确，重新构建镜像 |
| ARM Mac 构建失败 | 确保设置了 `--platform linux/amd64`（EKS/x86 集群需要） |
