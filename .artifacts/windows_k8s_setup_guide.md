# Windows 10 Kubernetes 環境建置指南
## 針對算力管理與多租戶任務

---

## 🛠️ Phase 1: 安裝必要工具

### 1.1 安裝 Docker Desktop

**下載與安裝：**
1. 前往 [Docker Desktop 官網](https://www.docker.com/products/docker-desktop/)
2. 下載 Windows 版本
3. 執行安裝程式（安裝過程會要求啟用 WSL 2）
4. 重啟電腦

**啟用 WSL 2（如果尚未啟用）：**
```powershell
# 在 PowerShell（管理員模式）執行
wsl --install
# 或如果已安裝 WSL，確保是 version 2
wsl --set-default-version 2
```

**設定 Docker Desktop：**
1. 開啟 Docker Desktop
2. Settings → Resources → 設定資源：
   - Memory: 16GB（你有 64GB 所以綽綽有餘）
   - CPUs: 8 cores
   - Swap: 2GB
3. 點擊 "Apply & Restart"

**驗證安裝：**
```powershell
# 開啟 PowerShell 或 CMD
docker --version
docker run hello-world
```

---

### 1.2 安裝 kubectl（Kubernetes 命令列工具）

**方法 A：使用 Chocolatey（推薦）**
```powershell
# 如果還沒安裝 Chocolatey，先安裝它
# 在 PowerShell（管理員模式）執行：
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安裝 kubectl
choco install kubernetes-cli
```

**方法 B：手動下載**
1. 前往 [kubectl releases](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)
2. 下載最新版 `kubectl.exe`
3. 將檔案移到 `C:\Program Files\kubectl\`
4. 加入系統 PATH 環境變數

**驗證安裝：**
```powershell
kubectl version --client
```

---

### 1.3 安裝 Kind（Kubernetes in Docker）

**使用 Chocolatey 安裝：**
```powershell
choco install kind
```

**或使用 PowerShell 手動安裝：**
```powershell
# 下載 kind
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
# 移動到適當位置
Move-Item .\kind-windows-amd64.exe C:\kind.exe
# 加入 PATH（或直接用完整路徑）
```

**驗證安裝：**
```powershell
kind version
```

---

### 1.4 安裝 Helm（Kubernetes 套件管理工具）

```powershell
choco install kubernetes-helm
```

**驗證安裝：**
```powershell
helm version
```

---

## 🚀 Phase 2: 建立你的第一個 K8s 叢集

### 2.1 建立 Kind 叢集配置檔

建立檔案 `kind-cluster-config.yaml`：

```yaml
# kind-cluster-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: multi-tenant-cluster
nodes:
  # Control plane node
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
  
  # Worker nodes（模擬多節點環境）
  - role: worker
    labels:
      node-type: compute
  - role: worker
    labels:
      node-type: compute
```

### 2.2 建立叢集

```powershell
# 建立叢集
kind create cluster --config kind-cluster-config.yaml

# 等待所有元件就緒（約 2-3 分鐘）
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# 檢查叢集狀態
kubectl cluster-info
kubectl get nodes
```

**預期輸出：**
```
NAME                                STATUS   ROLES           AGE   VERSION
multi-tenant-cluster-control-plane  Ready    control-plane   2m    v1.27.3
multi-tenant-cluster-worker         Ready    <none>          2m    v1.27.3
multi-tenant-cluster-worker2        Ready    <none>          2m    v1.27.3
```

---

## 🧪 Phase 3: 驗證環境

### 3.1 執行你的第一個 Pod

建立測試檔案 `test-pod.yaml`：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-nginx
  labels:
    app: test
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

執行：
```powershell
kubectl apply -f test-pod.yaml
kubectl get pods -w  # 監看 Pod 狀態（Ctrl+C 停止）
```

### 3.2 測試 Port Forwarding

```powershell
# 將 Pod 的 80 port 轉發到本地 8080
kubectl port-forward test-nginx 8080:80
```

在瀏覽器開啟 `http://localhost:8080`，應該會看到 Nginx 歡迎頁面。

### 3.3 清理測試資源

```powershell
kubectl delete pod test-nginx
```

---

## 🏗️ Phase 4: 建立多租戶原型環境

### 4.1 建立租戶 Namespaces

建立檔案 `multi-tenant-setup.yaml`：

```yaml
---
# Namespace for Tenant A
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-a
  labels:
    tenant: tenant-a

---
# Namespace for Tenant B
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-b
  labels:
    tenant: tenant-b

---
# Namespace for Monitoring
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring

---
# ResourceQuota for Tenant A
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-a-quota
  namespace: tenant-a
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "10"
    services: "5"

---
# ResourceQuota for Tenant B
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-b-quota
  namespace: tenant-b
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    pods: "5"
    services: "3"

---
# NetworkPolicy: Tenant A isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-a-isolation
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: tenant-a
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tenant: tenant-a
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

執行：
```powershell
kubectl apply -f multi-tenant-setup.yaml

# 驗證
kubectl get namespaces
kubectl describe quota -n tenant-a
kubectl describe quota -n tenant-b
```

### 4.2 部署測試服務到各租戶

建立檔案 `tenant-services.yaml`：

```yaml
---
# Tenant A: 簡單的 echo service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-service
  namespace: tenant-a
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo
      tenant: tenant-a
  template:
    metadata:
      labels:
        app: echo
        tenant: tenant-a
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo:latest
        args:
        - "-text=Hello from Tenant A"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"

---
# Service for Tenant A
apiVersion: v1
kind: Service
metadata:
  name: echo-service
  namespace: tenant-a
spec:
  selector:
    app: echo
    tenant: tenant-a
  ports:
  - port: 80
    targetPort: 8080

---
# Tenant B: 類似的服務
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-service
  namespace: tenant-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
      tenant: tenant-b
  template:
    metadata:
      labels:
        app: echo
        tenant: tenant-b
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo:latest
        args:
        - "-text=Hello from Tenant B"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"

---
# Service for Tenant B
apiVersion: v1
kind: Service
metadata:
  name: echo-service
  namespace: tenant-b
spec:
  selector:
    app: echo
    tenant: tenant-b
  ports:
  - port: 80
    targetPort: 8080
```

執行：
```powershell
kubectl apply -f tenant-services.yaml

# 檢查部署狀態
kubectl get deployments -n tenant-a
kubectl get deployments -n tenant-b
kubectl get pods -n tenant-a
kubectl get pods -n tenant-b
```

### 4.3 測試租戶服務

```powershell
# Tenant A
kubectl port-forward -n tenant-a svc/echo-service 8081:80
# 開啟瀏覽器: http://localhost:8081

# Tenant B（另開一個 PowerShell）
kubectl port-forward -n tenant-b svc/echo-service 8082:80
# 開啟瀏覽器: http://localhost:8082
```

---

## 📊 Phase 5: 安裝監控工具

### 5.1 安裝 Prometheus + Grafana（使用 Helm）

```powershell
# 新增 Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安裝 kube-prometheus-stack（包含 Prometheus、Grafana、Alertmanager）
helm install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --create-namespace `
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# 等待部署完成
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s
```

### 5.2 存取 Grafana

```powershell
# 取得 Grafana 預設密碼
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

開啟瀏覽器：`http://localhost:3000`
- Username: `admin`
- Password: （上面指令輸出的密碼）

---

## 🎓 常用指令速查表

```powershell
# === 叢集管理 ===
kind get clusters                    # 列出所有叢集
kind delete cluster --name <name>    # 刪除叢集
kubectl cluster-info                 # 叢集資訊

# === Namespace ===
kubectl get namespaces               # 列出所有 namespace
kubectl create namespace <name>      # 建立 namespace
kubectl config set-context --current --namespace=<name>  # 切換預設 namespace

# === Pod 管理 ===
kubectl get pods -n <namespace>      # 列出 Pods
kubectl describe pod <name> -n <ns>  # Pod 詳細資訊
kubectl logs <pod-name> -n <ns>      # 查看 logs
kubectl exec -it <pod> -n <ns> -- /bin/bash  # 進入 Pod

# === 資源管理 ===
kubectl apply -f <file.yaml>         # 套用配置
kubectl delete -f <file.yaml>        # 刪除資源
kubectl get all -n <namespace>       # 列出所有資源

# === 除錯工具 ===
kubectl get events -n <namespace>    # 查看事件
kubectl top nodes                    # 節點資源使用
kubectl top pods -n <namespace>      # Pod 資源使用

# === Port Forwarding ===
kubectl port-forward <resource> <local-port>:<remote-port> -n <ns>
```

---

## 🔧 故障排除

### 問題：Docker Desktop 啟動失敗
**解決方案：**
1. 確認 WSL 2 已正確安裝：`wsl --status`
2. 確認虛擬化已啟用（BIOS 設定）
3. 重新安裝 Docker Desktop

### 問題：kubectl 找不到指令
**解決方案：**
1. 確認已加入 PATH 環境變數
2. 重新開啟 PowerShell
3. 使用完整路徑執行

### 問題：Pod 一直處於 Pending 狀態
**解決方案：**
```powershell
kubectl describe pod <pod-name> -n <namespace>
# 查看 Events 區域的錯誤訊息
```

常見原因：
- 資源不足（超過 ResourceQuota）
- Image pull 失敗
- Node selector 不匹配

### 問題：無法存取 Service
**解決方案：**
```powershell
# 檢查 Service 是否正確
kubectl get svc -n <namespace>

# 檢查 Endpoints（Service 是否正確連接到 Pods）
kubectl get endpoints -n <namespace>

# 測試 Service 連線
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
# 在容器內：curl http://<service-name>.<namespace>.svc.cluster.local
```

---

## 🎯 下一步：開始你的任務

現在你有了：
- ✅ 本地 K8s 叢集
- ✅ 多租戶 Namespace 隔離
- ✅ ResourceQuota 配額管理
- ✅ 基本監控工具（Prometheus + Grafana）

**接下來的任務：**
1. 整合 LiteLLM（Day 3-4）
2. 設定 API Gateway（Day 5-6）
3. 建立監控面板（Day 7-8）
4. 撰寫完整文檔（Day 9-10）

---

## 📚 參考資源

- [Kind 官方文檔](https://kind.sigs.k8s.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Charts](https://artifacthub.io/)
- [K8s 官方教學](https://kubernetes.io/docs/tutorials/)

**環境準備完成！準備好挑戰了嗎？** 🚀
