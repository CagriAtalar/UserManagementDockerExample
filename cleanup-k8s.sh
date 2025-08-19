#!/bin/bash

# User Management Kubernetes Cleanup Script

set -e

echo "🧹 User Management Kubernetes Cleanup Başlatılıyor..."

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Namespace'deki tüm resource'ları sil
echo -e "${YELLOW}Kubernetes resource'ları siliniyor...${NC}"
kubectl delete namespace user-management --ignore-not-found=true

# Image'ları containerd'den temizle (opsiyonel)
read -p "Container image'larını da temizlemek istiyor musunuz? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Container image'ları temizleniyor...${NC}"
    
    # Master node'dan image'ları sil
    sudo ctr -n k8s.io images rm docker.io/library/user-management-backend:latest || true
    sudo ctr -n k8s.io images rm docker.io/library/user-management-frontend:latest || true
    
    # Worker node'dan image'ları sil
    ssh root@192.168.0.233 'ctr -n k8s.io images rm docker.io/library/user-management-backend:latest' || true
    ssh root@192.168.0.233 'ctr -n k8s.io images rm docker.io/library/user-management-frontend:latest' || true
    
    echo -e "${GREEN}✅ Image'lar temizlendi!${NC}"
fi

# PV'leri kontrol et ve temizle
echo -e "${YELLOW}Persistent Volume'lar kontrol ediliyor...${NC}"
kubectl get pv | grep user-management || echo "PV bulunamadı"

echo -e "${GREEN}✅ Cleanup tamamlandı!${NC}"
