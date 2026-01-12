# SQL ConfigMap 挂载部署说明

## 📋 概述

现在 Flink SQL 文件通过 Kubernetes ConfigMap 挂载到 Pod 中，这样可以：
- ✅ 无需重新构建镜像即可更新 SQL
- ✅ SQL 文件作为配置管理，便于版本控制
- ✅ 快速迭代和测试 SQL 变更

## 🚀 部署步骤

### 1. 创建 SQL ConfigMap

```bash
# 进入 k8s 目录
cd /Users/chenlingu/Codes/schemetic/k8s

# 创建 ConfigMap
kubectl apply -f sql-configmap.yaml
```

**验证 ConfigMap：**
```bash
kubectl get configmap flink-sql-config
kubectl describe configmap flink-sql-config
```

### 2. 部署 FlinkDeployment

```bash
# 部署 Flink 应用
kubectl apply -f app.yaml
```

### 3. 验证 SQL 文件挂载

```bash
# 获取 Pod 名称并查看挂载的 SQL 文件
kubectl exec -it <pod-name> -- cat /opt/flink/sql/pipeline.sql
```

## 🔄 更新 SQL 文件

当需要修改 SQL 时，**不需要重新构建镜像**，只需：

### 方式 1：直接修改 ConfigMap（快速测试）

```bash
kubectl edit configmap flink-sql-config
# 然后重启 Pod
kubectl delete pod -l app=<your-app>
```

### 方式 2：更新 YAML 文件（推荐）

1. 修改 `k8s/sql-configmap.yaml` 中的 SQL 内容
2. 应用更新：
   ```bash
   kubectl apply -f sql-configmap.yaml
   kubectl delete pod -l app=<your-app>
   ```

## 📄 已修改的文件

1. **[`sql-configmap.yaml`](file:///Users/chenlingu/Codes/schemetic/k8s/sql-configmap.yaml)** - 新建
   - 包含完整的 pipeline.sql 内容
   
2. **[`app.yaml`](file:///Users/chenlingu/Codes/schemetic/k8s/app.yaml)** - 已更新
   - 添加了 sql-config volume
   - 添加了 /opt/flink/sql volumeMount

## ⚙️ ConfigMap 挂载说明

**Volume 配置：**
```yaml
- name: sql-config
  configMap:
    name: flink-sql-config
```

**VolumeMount 配置：**
```yaml
- name: sql-config
  mountPath: /opt/flink/sql
  readOnly: true
```

这样 ConfigMap 中的 `pipeline.sql` 会自动挂载到 `/opt/flink/sql/pipeline.sql`。

## 🎯 优势

- **快速迭代**：修改 SQL 后只需更新 ConfigMap 和重启 Pod
- **版本控制**：SQL 变更都在 Git 中
- **环境隔离**：不同环境可使用不同的 ConfigMap
- **无需构建镜像**：节省大量时间

完成！现在可以直接修改 `sql-configmap.yaml` 来更新 SQL 逻辑了。
