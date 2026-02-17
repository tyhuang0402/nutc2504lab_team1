# K8s 診斷腳本
# 檢查各種可能的問題

Write-Host "=== Kubernetes 環境診斷 ===" -ForegroundColor Cyan

Write-Host "`n1. 檢查 Minikube 狀態" -ForegroundColor Yellow
minikube status

Write-Host "`n2. 檢查所有 Namespace" -ForegroundColor Yellow
kubectl get namespaces

Write-Host "`n3. 檢查 tenant-a namespace 是否存在" -ForegroundColor Yellow
kubectl get namespace tenant-a

Write-Host "`n4. 檢查 tenant-a 中的所有資源" -ForegroundColor Yellow
kubectl get all -n tenant-a

Write-Host "`n5. 檢查是否有 ConfigMap" -ForegroundColor Yellow
kubectl get configmaps -n tenant-a

Write-Host "`n6. 檢查是否有 Deployment" -ForegroundColor Yellow
kubectl get deployments -n tenant-a

Write-Host "`n7. 檢查是否有 Pod" -ForegroundColor Yellow
kubectl get pods -n tenant-a

Write-Host "`n8. 如果有 Pod，查看詳細狀態" -ForegroundColor Yellow
$pods = kubectl get pods -n tenant-a -o name 2>$null
if ($pods) {
    foreach ($pod in $pods) {
        Write-Host "`n詳細資訊：$pod" -ForegroundColor Green
        kubectl describe $pod -n tenant-a
    }
} else {
    Write-Host "沒有 Pod 在 tenant-a namespace" -ForegroundColor Red
}

Write-Host "`n9. 檢查最近的事件" -ForegroundColor Yellow
kubectl get events -n tenant-a --sort-by='.lastTimestamp'