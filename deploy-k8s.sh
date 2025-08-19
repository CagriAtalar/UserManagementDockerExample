#!/bin/bash

# User Management Kubernetes Deployment Script
# Bu script 2 node'lu cluster için hazırlanmıştır
# Master: 192.168.0.146, Worker: 192.168.0.233

set -e

echo "🚀 User Management Kubernetes Deployment Başlatılıyor..."

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Container image'larını build et
echo -e "${BLUE}📦 Container image'ları build ediliyor...${NC}"

# Backend image build
echo -e "${YELLOW}Backend image build ediliyor...${NC}"
docker build -t user-management-backend:latest ./backend/

# Frontend image build
echo -e "${YELLOW}Frontend image build ediliyor...${NC}"
docker build -t user-management-frontend:latest ./frontend/

# Image'ları containerd'ye yükle (her node için)
echo -e "${BLUE}📤 Image'lar node'lara dağıtılıyor...${NC}"

# Master node'a image yükle
echo -e "${YELLOW}Master node'a image'lar yükleniyor...${NC}"
docker save user-management-backend:latest | sudo ctr -n k8s.io images import -
docker save user-management-frontend:latest | sudo ctr -n k8s.io images import -

# Worker node'a image gönder (SSH ile)
echo -e "${YELLOW}Worker node'a image'lar gönderiliyor...${NC}"
docker save user-management-backend:latest | gzip | ssh root@192.168.0.233 'gunzip | ctr -n k8s.io images import -'
docker save user-management-frontend:latest | gzip | ssh root@192.168.0.233 'gunzip | ctr -n k8s.io images import -'

# Kubernetes resource'larını deploy et
echo -e "${BLUE}☸️ Kubernetes resource'ları deploy ediliyor...${NC}"

# Namespace oluştur
echo -e "${YELLOW}Namespace oluşturuluyor...${NC}"
kubectl apply -f k8s/namespace.yaml

# PostgreSQL deploy et
echo -e "${YELLOW}PostgreSQL deploy ediliyor...${NC}"
kubectl apply -f k8s/postgres-deployment.yaml

# PostgreSQL'in hazır olmasını bekle
echo -e "${YELLOW}PostgreSQL'in hazır olması bekleniyor...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n user-management --timeout=300s

# Backend deploy et
echo -e "${YELLOW}Backend deploy ediliyor...${NC}"
kubectl apply -f k8s/backend-deployment.yaml

# Backend'in hazır olmasını bekle
echo -e "${YELLOW}Backend'in hazır olması bekleniyor...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n user-management --timeout=300s

# Frontend deploy et
echo -e "${YELLOW}Frontend deploy ediliyor...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml

# Network policies uygula
echo -e "${YELLOW}Network policies uygulanıyor...${NC}"
kubectl apply -f k8s/network-policies.yaml

# Ingress oluştur
echo -e "${YELLOW}Ingress oluşturuluyor...${NC}"
kubectl apply -f k8s/ingress.yaml

# Deployment durumunu kontrol et
echo -e "${BLUE}📊 Deployment durumu kontrol ediliyor...${NC}"
kubectl get all -n user-management

# LoadBalancer IP adresini göster
echo -e "${BLUE}🌐 LoadBalancer IP adresi:${NC}"
kubectl get svc frontend-service -n user-management -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo ""

# Pod dağılımını göster
echo -e "${BLUE}📍 Pod dağılımı:${NC}"
kubectl get pods -n user-management -o wide

echo -e "${GREEN}✅ Deployment tamamlandı!${NC}"
echo -e "${YELLOW}📝 Notlar:${NC}"
echo -e "   • Frontend LoadBalancer IP'si üzerinden erişilebilir"
echo -e "   • Backend 3 replica ile çalışıyor"
echo -e "   • Network policies aktif"
echo -e "   • PostgreSQL persistent storage kullanıyor"
echo -e ""
echo -e "${BLUE}🔧 Faydalı komutlar:${NC}"
echo -e "   kubectl get all -n user-management"
echo -e "   kubectl logs -f deployment/backend -n user-management"
echo -e "   kubectl logs -f deployment/frontend -n user-management"
echo -e "   kubectl describe networkpolicy -n user-management"
