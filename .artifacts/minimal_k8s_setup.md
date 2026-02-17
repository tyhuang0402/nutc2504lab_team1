# Kubernetes 極簡環境指南
## Minikube + 純命令列 | 最小化安裝

> 目標：用最少的系統改動建立 K8s 學習環境

---

## 🎯 方案概述

**安裝內容**：
1. kubectl.exe（單一執行檔）
2. minikube.exe（單一執行檔）
3. Hyper-V（Windows 內建虛擬化，只需啟用）

**不需要**：
- ❌ Docker Desktop
- ❌ WSL 2
- ❌ Chocolatey
- ❌ 任何複雜的安裝程式

**系統改動**：
- ✅ 只啟用 Hyper-V（Windows 內建功能）
- ✅ 兩個 .exe 檔案放在一個資料夾
- ✅ Minikube 的 VM 資料存在可控的位置

---

## 📋 Step 1: 啟用 Hyper-V

**什麼是 Hyper-V？**
Windows 內建的虛擬化技術，Minikube 會用它建立一個輕量 VM 來跑 K8s。

### 檢查是否可用 Hyper-V

1. **開啟 PowerShell（系統管理員）**：
```powershell
# 檢查是否支援虛擬化
systeminfo | findstr /C:"Hyper-V"

# 如果顯示 "已偵測到 Hypervisor。不會顯示 Hyper-V 所需的功能。" 
# → 代表已啟用
# 如果顯示 "Hyper-V Requirements: ..." 
# → 需要手動啟用
```

### 啟用 Hyper-V（如果未啟用）

```powershell
# 方式 1: 用指令啟用（推薦）
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# 方式 2: 用 GUI 啟用
# 控制台 → 程式和功能 → 開啟或關閉 Windows 功能 → 勾選 Hyper-V → 確定
```

**重要**：啟用後需要重新啟動電腦

---

## 📦 Step 2: 下載 kubectl 和 Minikube

### 建立專屬資料夾

```powershell
# 建立一個乾淨的資料夾來存放所有 K8s 工具
mkdir C:\k8s-tools
cd C:\k8s-tools
```

### 下載 kubectl

```powershell
# 下載 kubectl（約 50MB）
curl.exe -LO "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"

# 驗證下載
.\kubectl.exe version --client
```

### 下載 Minikube

```powershell
# 下載 Minikube（約 80MB）
curl.exe -LO "https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe"

# 重新命名為簡單的名字
Rename-Item .\minikube-windows-amd64.exe minikube.exe

# 驗證下載
.\minikube.exe version
```

### 設定 PATH（方便使用）

**選項 A：永久加入 PATH**（會動到 registry，但很乾淨）
```powershell
# 將 C:\k8s-tools 加入使用者 PATH
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\k8s-tools", "User")

# 重新開啟 PowerShell 後就可以直接用 kubectl 和 minikube
```

**選項 B：臨時加入 PATH**（完全不動 registry）
```powershell
# 每次開新 PowerShell 都要執行這行
$env:Path += ";C:\k8s-tools"

# 或者建立一個 PowerShell profile script
# 放在 $PROFILE 檔案中，每次啟動自動執行
```

**選項 C：不加 PATH**（最純淨，但要用完整路徑）
```powershell
# 每次都要用完整路徑或 cd 到該目錄
C:\k8s-tools\kubectl.exe get pods
C:\k8s-tools\minikube.exe start
```

---

## 🚀 Step 3: 啟動 Minikube

### 基本啟動（使用 Hyper-V）

```powershell
# 第一次啟動（會下載約 400MB 的 K8s ISO 映像）
minikube start --driver=hyperv

# 設定為預設 driver（之後就不用加 --driver）
minikube config set driver hyperv
```

**啟動選項說明**：
```powershell
# 最小化配置（適合學習）
minikube start --driver=hyperv --cpus=2 --memory=4096

# 指定 K8s 版本
minikube start --driver=hyperv --kubernetes-version=v1.28.0

# 指定 Minikube 資料存放位置（方便管理）
minikube start --driver=hyperv --profile=my-cluster
```

### 驗證 K8s 運行中

```powershell
# 檢查 Minikube 狀態
minikube status
# 應該顯示：
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running

# 檢查 K8s 節點
kubectl get nodes
# 應該顯示一個 minikube 節點，狀態 Ready

# 檢查系統 Pods
kubectl get pods -A
# 會顯示 kube-system namespace 中的系統元件
```

---

## 🧹 重要：如何完全清除

這是最關鍵的部分——確保你可以乾淨移除。

### 刪除 Minikube 叢集

```powershell
# 停止並刪除 Minikube VM
minikube delete

# 這會：
# - 刪除 Hyper-V 中的 VM
# - 清除 C:\Users\你的使用者名\.minikube 資料夾
```

### 刪除所有 Minikube 資料

```powershell
# 刪除 Minikube 配置和快取
Remove-Item -Recurse -Force "$env:USERPROFILE\.minikube"
Remove-Item -Recurse -Force "$env:USERPROFILE\.kube"

# 刪除下載的執行檔
Remove-Item -Recurse -Force "C:\k8s-tools"
```

### 移除 PATH 設定（如果有加）

```powershell
# 如果之前加入了 PATH，移除它
# 打開 系統設定 → 環境變數 → 使用者變數 → Path
# 手動移除 C:\k8s-tools
```

### 關閉 Hyper-V（如果想完全還原）

```powershell
# 完全關閉 Hyper-V（會需要重啟）
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

**清除後狀態**：
- ✅ 無任何殘留程式
- ✅ Registry 只剩 Hyper-V 啟用記錄（Windows 內建功能）
- ✅ 可以用 Windows 功能面板關閉 Hyper-V

---

## 📚 基本使用範例

### 例子 1：建立第一個 Pod

```powershell
# 建立 namespace
kubectl create namespace test

# 部署 nginx
kubectl run nginx --image=nginx --namespace=test

# 查看
kubectl get pods -n test

# 清理
kubectl delete namespace test
```

### 例子 2：使用 YAML 檔案

建立 `test.yaml`：
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-a
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: tenant-a
spec:
  containers:
  - name: nginx
    image: nginx:latest
```

部署：
```powershell
kubectl apply -f test.yaml
kubectl get pods -n tenant-a
kubectl delete -f test.yaml
```

---

## 🎓 Minikube 常用指令

```powershell
# === 叢集管理 ===
minikube start                    # 啟動
minikube stop                     # 停止（保留資料）
minikube delete                   # 完全刪除
minikube status                   # 查看狀態
minikube pause                    # 暫停（不佔 CPU）
minikube unpause                  # 恢復

# === 資源管理 ===
minikube ssh                      # SSH 進入 VM
minikube dashboard                # 開啟 Web UI（會開瀏覽器）
minikube addons list              # 列出可用插件
minikube addons enable metrics-server  # 啟用插件

# === 資訊查詢 ===
minikube ip                       # 取得 VM IP
minikube logs                     # 查看日誌
```

---

## 💾 Minikube 資料存放位置

了解資料存放在哪裡，方便管理和備份：

```
C:\Users\你的使用者名\.minikube\
├── cache\                      # 下載的映像檔快取
├── machines\                   # Hyper-V VM 設定
├── profiles\                   # 不同叢集的設定
└── config\                     # Minikube 配置

C:\Users\你的使用者名\.kube\
└── config                      # kubectl 配置檔
```

---

## 🔍 為什麼這個方案適合你？

### Registry 改動最少
```
✅ Hyper-V 啟用（Windows 功能，可隨時關閉）
✅ PATH 環境變數（可選，且可輕易移除）
❌ 無其他 registry 改動
```

### 檔案系統乾淨
```
安裝後：
C:\k8s-tools\                   # 只有 2 個 .exe
C:\Users\你\.minikube\          # Minikube 資料
C:\Users\你\.kube\              # kubectl 配置

刪除後：
（空空如也，完全乾淨）
```

### 與其他方案比較

| 方案 | Registry 改動 | 檔案數量 | 移除難度 |
|------|--------------|---------|---------|
| **Minikube + Hyper-V** | 最少（僅 Hyper-V） | ~2 個 exe | 超簡單 |
| Docker Desktop | 多（整套 Docker） | 數百個檔案 | 困難 |
| WSL 2 | 中等 | 數千個檔案 | 中等 |
| Kind (需 Docker) | 多 | 數百個檔案 | 困難 |

---

## ⚠️ 限制與取捨

這個方案的限制（但對你的任務影響不大）：

1. **需要 Windows Pro/Enterprise**
   - Hyper-V 只在 Pro 以上版本可用
   - Home 版需要用 Docker Desktop 或 VirtualBox driver

2. **無法同時跑其他 Hyper-V VM**
   - 如果你需要用 VirtualBox，會衝突
   - 但單純學習 K8s 完全夠用

3. **效能略遜於原生**
   - 因為跑在 VM 中，有一點虛擬化開銷
   - 但對測試任務完全足夠

---

## 🎯 建議的工作流程

```powershell
# 1. 開始工作
minikube start

# 2. 做你的 K8s 實驗
kubectl apply -f ...

# 3. 完成後
minikube stop  # 或 minikube pause（更快）

# 4. 長時間不用
minikube delete  # 完全清除，下次重新 start
```

---

## 🆘 問題排解

### Minikube 啟動失敗

```powershell
# 檢查 Hyper-V 是否正確啟用
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# 嘗試用其他 driver（如果 Hyper-V 有問題）
minikube start --driver=virtualbox  # 需要先安裝 VirtualBox
```

### kubectl 連不上 Minikube

```powershell
# 重新設定 kubectl context
minikube update-context

# 檢查 config
kubectl config view
```

### 刪除卡住

```powershell
# 強制刪除
minikube delete --purge

# 手動清理殘留
Remove-Item -Recurse -Force "$env:USERPROFILE\.minikube"
```

---

## 📖 下一步

環境設定好後，你可以：

1. **建立多租戶環境**（用 namespace 隔離）
2. **部署 LiteLLM**（用 kubectl apply）
3. **設定 ResourceQuota**（限制算力）

這個極簡環境完全可以完成你的測試任務！

---

**總結**：
- 🎯 只需 2 個 .exe + 啟用 Hyper-V
- 🧹 用完 `minikube delete` 就乾淨了
- 💪 功能完整，足以完成任務
