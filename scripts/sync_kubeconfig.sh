#!/usr/bin/env bash

set -e

K3S_MASTER_IP="192.168.56.10"
TMP_CONFIG="./tmp_k3s.yaml"
FINAL_CONFIG="$HOME/.kube/config"

echo "[INFO] 從 k3s-master 抓取 kubeconfig..."
vagrant ssh k3s-master -c "sudo cat /etc/rancher/k3s/k3s.yaml" > "$TMP_CONFIG"

echo "[INFO] 替換 127.0.0.1 為 $K3S_MASTER_IP"
sed -i.bak "s/127.0.0.1/$K3S_MASTER_IP/g" "$TMP_CONFIG"

echo "[INFO] 建立 ~/.kube 資料夾（如果不存在）"
mkdir -p ~/.kube

echo "[INFO] 搬移 kubeconfig 到 $FINAL_CONFIG"
mv "$TMP_CONFIG" "$FINAL_CONFIG"

echo "[INFO] 設定完成，測試 kubectl:"
kubectl get nodes
