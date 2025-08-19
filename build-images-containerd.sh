#!/bin/bash

# User Management - Container Image Build Script (Containerd Compatible)
# Bu script Docker yerine buildah/podman kullanarak image build eder

set -e

echo "🔨 Container image'ları build ediliyor (Containerd için)..."

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build tool kontrolü
if command -v buildah &> /dev/null; then
    BUILD_TOOL="buildah"
elif command -v podman &> /dev/null; then
    BUILD_TOOL="podman"
elif command -v docker &> /dev/null; then
    BUILD_TOOL="docker"
else
    echo -e "${RED}❌ Hiçbir container build tool bulunamadı (buildah, podman, docker)${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Build tool: ${BUILD_TOOL}${NC}"

# Backend image build
echo -e "${YELLOW}Backend image build ediliyor...${NC}"
cd backend
$BUILD_TOOL build -t user-management-backend:latest .
cd ..

# Frontend image build
echo -e "${YELLOW}Frontend image build ediliyor...${NC}"
cd frontend
$BUILD_TOOL build -t user-management-frontend:latest \
    --build-arg REACT_APP_API_URL=http://backend-service:5000 .
cd ..

# Image'ları containerd namespace'ine import et
echo -e "${BLUE}📤 Image'lar containerd'ye import ediliyor...${NC}"

if [ "$BUILD_TOOL" = "docker" ]; then
    # Docker kullanılıyorsa, image'ları save/load ile containerd'ye aktarıyoruz
    echo -e "${YELLOW}Docker image'ları containerd'ye aktarılıyor...${NC}"
    docker save user-management-backend:latest | sudo ctr -n k8s.io images import -
    docker save user-management-frontend:latest | sudo ctr -n k8s.io images import -
elif [ "$BUILD_TOOL" = "podman" ]; then
    # Podman kullanılıyorsa
    echo -e "${YELLOW}Podman image'ları containerd'ye aktarılıyor...${NC}"
    podman save user-management-backend:latest | sudo ctr -n k8s.io images import -
    podman save user-management-frontend:latest | sudo ctr -n k8s.io images import -
elif [ "$BUILD_TOOL" = "buildah" ]; then
    # Buildah kullanılıyorsa
    echo -e "${YELLOW}Buildah image'ları containerd'ye aktarılıyor...${NC}"
    buildah push user-management-backend:latest oci-archive:/tmp/backend.tar
    buildah push user-management-frontend:latest oci-archive:/tmp/frontend.tar
    sudo ctr -n k8s.io images import /tmp/backend.tar
    sudo ctr -n k8s.io images import /tmp/frontend.tar
    rm -f /tmp/backend.tar /tmp/frontend.tar
fi

# Worker node'a image'ları gönder
echo -e "${BLUE}📤 Worker node'a image'lar gönderiliyor...${NC}"
echo -e "${YELLOW}192.168.0.233 worker node'ına image'lar aktarılıyor...${NC}"

if [ "$BUILD_TOOL" = "docker" ]; then
    docker save user-management-backend:latest | gzip | ssh root@192.168.0.233 'gunzip | ctr -n k8s.io images import -'
    docker save user-management-frontend:latest | gzip | ssh root@192.168.0.233 'gunzip | ctr -n k8s.io images import -'
elif [ "$BUILD_TOOL" = "podman" ]; then
    podman save user-management-backend:latest | gzip | ssh root@192.168.0.233 'gunzip | ctr -n k8s.io images import -'
    podman save user-management-frontend:latest | gzip | ssh root@192.168.0.233 'gunzip | ctr -n k8s.io images import -'
elif [ "$BUILD_TOOL" = "buildah" ]; then
    buildah push user-management-backend:latest oci-archive:/tmp/backend.tar
    buildah push user-management-frontend:latest oci-archive:/tmp/frontend.tar
    scp /tmp/backend.tar root@192.168.0.233:/tmp/
    scp /tmp/frontend.tar root@192.168.0.233:/tmp/
    ssh root@192.168.0.233 'ctr -n k8s.io images import /tmp/backend.tar && ctr -n k8s.io images import /tmp/frontend.tar && rm -f /tmp/*.tar'
    rm -f /tmp/backend.tar /tmp/frontend.tar
fi

# Image'ların containerd'de olduğunu kontrol et
echo -e "${BLUE}📋 Containerd image'ları kontrol ediliyor...${NC}"
echo -e "${YELLOW}Master node:${NC}"
sudo ctr -n k8s.io images ls | grep user-management || echo "Image bulunamadı!"

echo -e "${YELLOW}Worker node:${NC}"
ssh root@192.168.0.233 'ctr -n k8s.io images ls | grep user-management' || echo "Worker node'da image bulunamadı!"

echo -e "${GREEN}✅ Image build ve dağıtım tamamlandı!${NC}"
echo -e "${BLUE}🔧 Artık Kubernetes deploy edebilirsiniz:${NC}"
echo -e "   kubectl apply -k k8s/"
