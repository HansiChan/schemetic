## Argo CD 友好目录结构

该目录提供了一个独立于 `k8s/` 的 Kustomize 布局，方便直接在 Argo CD 中作为 `Directory` 源使用。

### 结构概览

```
k8s-argocd/
  base/
    app.yaml              # FlinkDeployment 清单（使用 Kustomize vars 做占位）
    app-config.yaml       # 控制变量的 ConfigMap（名称、镜像等）
    namespace.yaml        # 确保命名空间存在
    env/
      config.env.example  # 非敏感配置示例
      secret.env.example  # 敏感配置示例
      .gitignore          # 忽略实际 env/secret 文件
    kustomization.yaml    # 把上述资源组合在一起
```

### 使用方法

1. 复制示例环境文件并填入实际值：
   ```bash
   cp k8s-argocd/base/env/config.env.example k8s-argocd/base/env/config.env
   cp k8s-argocd/base/env/secret.env.example k8s-argocd/base/env/secret.env
   ```
2. 根据需要修改 `app-config.yaml`（名称、命名空间、镜像等）以及 `app.yaml` 中的资源规格。
3. 在 Argo CD Application 中将 `path` 指向 `k8s-argocd/base`，source type 选择 `Kustomize`。Argo 会运行 `kustomize build k8s-argocd/base` 并应用所有资源。

可以通过复制 `base/` 形成不同 overlay（例如 `k8s-argocd/overlays/prod`）来覆盖 `app-config.yaml` 或添加补丁，而无需改动原有 `k8s/` 目录。
