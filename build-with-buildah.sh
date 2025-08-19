#!/bin/bash

# Manual build script with buildah for containerd

set -e

echo "🔨 Buildah ile image build ediliyor..."

# Buildah var mı kontrol et
if ! command -v buildah &> /dev/null; then
    echo "❌ Buildah bulunamadı. Kurulum:"
    echo "sudo apt install buildah"
    exit 1
fi

# Backend build
echo "📦 Backend build ediliyor..."
cd backend

buildah bud --network=host --isolation=chroot -t user-management-backend:latest .

# Image'ı containerd'ye aktar
echo "📤 Backend image containerd'ye aktarılıyor..."
buildah push user-management-backend:latest oci-archive:/tmp/backend.tar
sudo ctr -n k8s.io images import /tmp/backend.tar
rm -f /tmp/backend.tar

cd ..

# Frontend build
echo "📦 Frontend build ediliyor..."
cd frontend

buildah bud --network=host --isolation=chroot -t user-management-frontend:latest \
    --build-arg REACT_APP_API_URL=http://backend-service:5000 .

# Image'ı containerd'ye aktar
echo "📤 Frontend image containerd'ye aktarılıyor..."
buildah push user-management-frontend:latest oci-archive:/tmp/frontend.tar
sudo ctr -n k8s.io images import /tmp/frontend.tar
rm -f /tmp/frontend.tar

cd ..

# Worker node'a gönder
echo "📤 Worker node'a image'lar gönderiliyor..."
buildah push user-management-backend:latest oci-archive:/tmp/backend.tar
buildah push user-management-frontend:latest oci-archive:/tmp/frontend.tar

scp /tmp/backend.tar root@192.168.0.233:/tmp/
scp /tmp/frontend.tar root@192.168.0.233:/tmp/

ssh root@192.168.0.233 'ctr -n k8s.io images import /tmp/backend.tar && ctr -n k8s.io images import /tmp/frontend.tar && rm -f /tmp/*.tar'

rm -f /tmp/backend.tar /tmp/frontend.tar

echo "✅ Build tamamlandı!"
echo "🔍 Containerd image'ları:"
sudo ctr -n k8s.io images ls | grep user-management
