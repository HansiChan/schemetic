# Schemetic — Flink SQL on Paimon (K8s)

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
  - [7. Configure Kubernetes](#7-configure-kubernetes)
  - [8. Deploy to Kubernetes](#8-deploy-to-kubernetes)
- [Image Variants](#image-variants)
- [CA Certificate Handling](#ca-certificate-handling)
- [Customization](#customization)
- [Uninstall / Cleanup](#uninstall--cleanup)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool | Purpose |
|---|---|
| **Docker** | Build and push images |
| **GNU Make** | Build automation |
| **kubectl** | Configured K8s cluster access |
| **envsubst** (gettext) | K8s manifest template rendering |
| **Flink K8s Operator** | Flink CRD and Operator installed in the cluster |

---

## Repository Layout

```
schemetic/
├── VERSION                          # Image version number
├── Makefile                         # Project scaffolding (create.project.*)
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
│   │   ├── common.env               # Shared build variables (registry, project name, etc.)
│   │   └── common.local.env         # Local overrides (gitignored, create manually)
│   └── build/
│       ├── dev/                     # Debian-based build
│       ├── amazone/                 # Amazon Linux 2023 build
│       │   ├── Dockerfile           # Standard (single-stage)
│       │   ├── Dockerfile.slim      # Slim (three-stage, recommended for production)
│       │   ├── Makefile
│       │   ├── requirements.txt     # Python dependencies
│       │   └── minio-ca.crt         # MinIO CA certificate
│       └── shared/                  # Shared build logic
├── k8s/
│   ├── app.yaml                     # FlinkDeployment template
│   ├── Makefile                     # K8s deployment automation
│   ├── .env                         # K8s deployment variables
│   └── env/
│       ├── config.env               # Non-sensitive env vars (gitignored)
│       └── secret.env               # Sensitive env vars (gitignored)
└── argo/                            # ArgoCD / Kustomize configuration
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/HansiChan/schemetic.git
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
APP_NAME=dwd_ewallet
IMAGE_TAG=0.1.0
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

> **Note on image tags**: When using `make build.app` without `IMAGE=`, the default tag is `{IMAGE_REPO_ROOT}/{PROJECT_NAME}_{APP_NAME}:amazone`. The Dockerfile choice (standard vs slim) does **not** affect the tag — pass `IMAGE=` explicitly if you need a version-specific tag.

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

### 7. Configure Kubernetes

#### 7.1 Edit Deployment Variables

Edit `k8s/.env`:

```env
# Image info (change to your actual pushed image)
IMAGE_REPO_ROOT=quay.io/<your-org>
DEV_IMAGE_NAME=flink_base
DEV_IMAGE_TAG=0.1.0-amazone-slim
DEV_IMAGE=${IMAGE_REPO_ROOT}/${DEV_IMAGE_NAME}:${DEV_IMAGE_TAG}

# K8s config
NAME=ewallet-dwd-pipeline        # FlinkDeployment name
NAMESPACE=flink                   # K8s namespace
SERVICE_ACCOUNT=flink             # K8s ServiceAccount

# Flink config
FLINK_VERSION=v1_20
FLINK_DEPLOY_MODE=native
```

#### 7.2 Create Environment Variable Files

**Non-sensitive variables** — `k8s/env/config.env`:

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

**Sensitive variables** — `k8s/env/secret.env`:

```env
S3_ACCESS_KEY=<your-access-key>
S3_SECRET_KEY=<your-secret-key>
```

> ⚠️ `secret.env` is excluded by `.gitignore` — do not commit it to Git.

#### 7.3 Verify PVC

Ensure a PersistentVolumeClaim named `flink-data` exists in the target namespace for Checkpoint and Savepoint storage.

### 8. Deploy to Kubernetes

```bash
cd k8s

# One-click deploy (creates namespace, ConfigMap, Secret, and applies FlinkDeployment)
make up

# Or step by step:
make ns            # Create namespace
make env.up        # Create/update ConfigMap (non-sensitive vars)
make secret.up     # Create/update Secret (sensitive vars)
```

Check deployment status:

```bash
make status                                      # View Pod status
kubectl logs -n flink <jobmanager-pod> -f         # View JobManager logs
kubectl logs -n flink <taskmanager-pod> -f        # View TaskManager logs
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
| Change Flink resources (CPU/memory) | Edit `jobManager` / `taskManager` in `k8s/app.yaml` |
| Adjust parallelism | Edit `job.parallelism` in `k8s/app.yaml` |
| Change checkpoint interval | Edit `CHECKPOINT_INTERVAL` in `k8s/env/config.env` |
| Add Python dependencies | Edit `docker/build/amazone/requirements.txt`, rebuild image |
| Update Flink/Paimon version | Edit versions in `flink-plugins/download-plugins.sh`, re-download and rebuild |
| Mount SQL via ConfigMap | See `k8s/SQL_CONFIGMAP_GUIDE.md` (no image rebuild needed) |

---

## Uninstall / Cleanup

```bash
# Delete K8s resources
cd k8s
make down

# Clean local Docker images
cd docker
make clean
```

---

## Troubleshooting

| Issue | Resolution |
|---|---|
| JAR download failure | Check network access to Maven Central, or manually download JARs into `flink-plugins/` |
| `envsubst` not found | Install gettext: `brew install gettext` (macOS) or `apt install gettext` (Linux) |
| CA/SSL errors | Verify `minio-ca.crt` is correct and check that `JAVA_TOOL_OPTIONS` is active in the Pod |
| `NoClassDefFoundError` | Missing JAR in `flink-plugins/` — re-run `download-plugins.sh` |
| Pod CrashLoopBackOff | Check JM logs: `kubectl logs -n flink <pod>` |
| SQL syntax errors | Debug in `pipeline.sql`, ensure `${VAR}` template syntax is correct |
| Multiple INSERTs not executing | `app.py` uses `StatementSet` to merge INSERTs — check logs to confirm all statements are parsed |
| Build fails on ARM Mac | Ensure `--platform linux/amd64` is set (required for EKS/x86 clusters) |
