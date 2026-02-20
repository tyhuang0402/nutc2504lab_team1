# NUTC 2504 Lab Team 1 Final Exam

2026寒假2504 AI工作坊 Team 1 招募作業
> 資工三A  1311432044 黃粲宇 \
> Email: silverstar53.www.ce@gmail.com \
> Line顯示名稱：W，有急事請以Line為優先聯絡 


# DocAI Multi-Tenancy PoC on Kubernetes

本專案為「算力管理與多租戶模組」招募測試任務的驗證原型，目標展示：

* 多租戶資源隔離
* API Key → 租戶 → 算力配額聯動
* LLM Gateway 統一入口
* GPU 使用率監控（可用 fake / real GPU）
* 可擴展至多叢集管理架構

---

# Architecture

```
Client
  ↓
LoadBalancer / Ingress
  ↓
API Gateway (API Key / Rate Limit)
  ↓
LiteLLM Proxy
  ↓
Tenant Namespace
  ↓
Model Pod (GPU Worker)
  ↓
DCGM Exporter
  ↓
Prometheus
  ↓
Grafana
```

---

# Environment

Host:

* Windows 10
* minikube (Hyper-V driver)

minikube addons:

* ingress
* metrics-server
* prometheus
* grafana

Pre-created namespaces:

```
tenant-a
tenant-b
```

---

# Quick Start (Local PoC – Fake GPU Mode)

## 1️⃣ Install Cilium

```bash
cilium install
cilium status
```

Verify:

```bash
kubectl get pods -n kube-system
```

---

## 2️⃣ Deploy LiteLLM Proxy

```bash
kubectl create ns lite
kubectl apply -f k8s/litellm/
```

Test:

```bash
kubectl port-forward svc/litellm 4000:4000 -n lite
```

---

## 3️⃣ Apply Tenant Resource Quota

```bash
kubectl apply -n tenant-a -f k8s/tenant/resourcequota.yaml
kubectl apply -n tenant-b -f k8s/tenant/resourcequota.yaml
```

Verify:

```bash
kubectl describe quota -n tenant-a
```

---

## 4️⃣ Deploy Fake GPU Metrics Exporter

```bash
kubectl apply -f k8s/dcgm/fake-gpu.yaml
```

Check metrics endpoint:

```bash
kubectl port-forward pod/<fake-gpu-pod> 9400
curl localhost:9400/metrics
```

---

## 5️⃣ Connect Prometheus

Apply ServiceMonitor:

```bash
kubectl apply -f k8s/monitoring/servicemonitor.yaml
```

Verify in Prometheus UI:

```
dcgm_gpu_utilization
```

---

## 6️⃣ Import Grafana Dashboard

Login Grafana → Import

```powershell
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Dashboard query:

```promql
avg by (namespace) (dcgm_gpu_utilization)
```

This shows per-tenant GPU usage.

---

# Demo Flow

### 1. Simulate Tenant Traffic

Send request to LiteLLM using tenant API key.

### 2. Observe Metrics

Grafana will show:

* tenant-a GPU usage
* tenant-b GPU usage

### 3. Quota Enforcement

When tenant exceeds quota:

Pod scheduling will fail.

---

# Tenant Provision API (Concept)

```
POST /tenants
```

Creates:

* Kubernetes namespace
* ResourceQuota
* Harbor project
* Grafana dashboard
* API key

# Multi-Cluster Scalability (Rancher)

Using Rancher:

* Centralized policy control
* Unified API Gateway config
* Fleet GitOps deployment
* Global quota template

---

# Project Structure

```
k8s/
 ├─ litellm/
 ├─ tenant/
 ├─ dcgm/
 └─ monitoring/
```

---

# ✅ Validation Checklist

* [ ] Multi-tenant namespaces
* [ ] ResourceQuota enforcement
* [ ] LiteLLM gateway working
* [ ] Per-tenant GPU metrics in Grafana
* [ ] API → traffic → quota linkage

---

