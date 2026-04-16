# Dagster + dbt + StarRocks 集成测试指南

## 概述
该环境协调 Dagster 和 dbt，并使用 StarRocks 作为计算引擎来处理 Paimon ODS 层数据。

- `dbt` 本身不能直接读取 Paimon，因此通过 StarRocks 的 External Catalog (`paimon_catalog`) 来读取。
- 整个环境被打包在 `docker/build/dbt` 目录中。

## 目录结构
```
docker/build/dbt/
├── Dockerfile                       # 打包 Python + Dagster + dbt + dbt-starrocks
├── requirements.txt                 # Python 依赖
├── dbt_project/
│   ├── dbt_project.yml              # dbt 项目配置
│   ├── profiles.yml                 # StarRocks 连接（通过环境变量注入）
│   └── models/
│       ├── ods/sources.yml          # ODS 源声明（指向 paimon_catalog）
│       └── dwd/example_dwd_model.sql
└── dagster_project/
    ├── project.py                   # DbtProject 定义
    └── definitions.py               # Dagster Definitions 入口
```

---

## 镜像构建

```bash
docker build -t <YOUR_REGISTRY>/dagster-dbt:latest ./docker/build/dbt
docker push <YOUR_REGISTRY>/dagster-dbt:latest
```

---

## 镜像使用说明

### 环境变量

镜像内的 `profiles.yml` 通过 `env_var()` 读取以下环境变量，**部署时必须通过 ConfigMap / Secret 注入**：

| 环境变量 | 说明 | 默认值 |
|---|---|---|
| `STARROCKS_HOST` | StarRocks FE 地址 | `127.0.0.1` |
| `STARROCKS_PORT` | StarRocks FE MySQL 协议端口 | `9030` |
| `STARROCKS_DATABASE` | 目标写入的数据库名（DWD 层） | `dwd` |
| `STARROCKS_USER` | 数据库用户 | `root` |
| `STARROCKS_PASSWORD` | 数据库密码 | 空 |

### 容器内核心路径

| 路径 | 说明 |
|---|---|
| `/opt/dagster/dagster_home` | Dagster Home，存放 `dagster.yaml` 和 `workspace.yaml` |
| `/opt/dagster/app/dbt_project` | dbt 项目目录 |
| `/opt/dagster/app/dagster_project` | Dagster 代码定义目录 |

### 暴露端口

| 端口 | 说明 |
|---|---|
| `3000` | Dagster Webserver UI |

### 默认启动命令

```
dagster-webserver -h 0.0.0.0 -p 3000
```

---

## Kustomize 部署注意事项

### 1. 基础 K8s 资源

你至少需要为该镜像创建以下 Kustomize 资源清单（建议参考现有的 `argo/base` + `argo/overlays/dev` 的分层模式）：

```yaml
# base/dagster-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dagster-dbt
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dagster-dbt
  template:
    metadata:
      labels:
        app: dagster-dbt
    spec:
      containers:
        - name: dagster-dbt
          image: <YOUR_REGISTRY>/dagster-dbt:latest
          ports:
            - containerPort: 3000
          envFrom:
            - configMapRef:
                name: dagster-dbt-config
            - secretRef:
                name: dagster-dbt-secret
---
apiVersion: v1
kind: Service
metadata:
  name: dagster-dbt
spec:
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: dagster-dbt
```

### 2. ConfigMap 和 Secret 注入环境变量

```yaml
# overlays/dev/dagster-dbt-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dagster-dbt-config
data:
  STARROCKS_HOST: "starrocks-fe.starrocks.svc.cluster.local"
  STARROCKS_PORT: "9030"
  STARROCKS_DATABASE: "dwd"
  STARROCKS_USER: "root"
```

```yaml
# overlays/dev/dagster-dbt-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dagster-dbt-secret
type: Opaque
stringData:
  STARROCKS_PASSWORD: "<YOUR_PASSWORD>"
```

### 3. Kustomize 中的镜像替换

在 `kustomization.yaml` 中使用 `images` 字段来管理镜像版本，方便 CI/CD 自动替换 tag：

```yaml
# overlays/dev/kustomization.yaml
images:
  - name: <YOUR_REGISTRY>/dagster-dbt
    newTag: "v1.0.0"  # CI/CD 流水线中可自动替换
```

### 4. ⚠️ 关键注意事项

| 注意项 | 说明 |
|---|---|
| **网络连通性** | 确保 Pod 所在的 namespace 能访问到 StarRocks FE 服务（同集群用 `svc.cluster.local`，跨集群用 ExternalName / Ingress）|
| **Paimon Catalog 须预先创建** | 镜像内的 dbt 只是通过 SQL 查询 StarRocks，**External Catalog 需要提前在 StarRocks 中执行 `CREATE EXTERNAL CATALOG` 语句**注册好 |
| **Dagster Daemon** | 如果需要 Schedule / Sensor 自动触发任务，仅靠 `dagster-webserver` 不够，还需额外部署一个 `dagster-daemon` 容器（可在同一 Deployment 中加 sidecar，或独立 Deployment）|
| **持久化存储** | 如需保留 Dagster 的 run history，建议给 `DAGSTER_HOME` 挂载 PVC，否则 Pod 重启后历史记录丢失 |
| **健康检查** | 建议配置 `livenessProbe` 和 `readinessProbe`，HTTP GET `/server_info` 端口 `3000` |
| **资源限制** | dbt compile/run 时会消耗内存，建议至少 `512Mi` memory request，`1Gi` limit |
