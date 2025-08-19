#!/bin/bash

# Simple build script that avoids network issues

set -e

echo "🔨 Basit build yöntemi..."

# Backend build
echo "📦 Backend build ediliyor..."
cd backend

# Buildah ile step by step build
container=$(buildah from node:18-alpine)
buildah config --workingdir /app $container
buildah copy $container package*.json ./
buildah run --network=host $container npm ci --only=production
buildah copy $container . .
buildah run $container mkdir -p /var/log
buildah run $container addgroup -g 1001 -S nodejs
buildah run $container adduser -S nodejs -u 1001
buildah run $container chown -R nodejs:nodejs /app /var/log
buildah config --user nodejs $container
buildah config --port 5000 $container
buildah config --cmd '["npm", "start"]' $container
buildah commit $container user-management-backend:latest
buildah rm $container

cd ..

# Frontend build
echo "📦 Frontend build ediliyor..."
cd frontend

container=$(buildah from node:18-alpine)
buildah config --workingdir /app $container
buildah copy $container package*.json ./
buildah run --network=host $container npm ci
buildah copy $container . .
buildah config --env REACT_APP_API_URL=http://backend-service:5000 $container
buildah run --network=host $container npm run build
buildah run --network=host $container npm install -g serve
buildah run $container addgroup -g 1001 -S nodejs
buildah run $container adduser -S nodejs -u 1001
buildah run $container chown -R nodejs:nodejs /app
buildah config --user nodejs $container
buildah config --port 3000 $container
buildah config --cmd '["serve", "-s", "build", "-l", "3000"]' $container
buildah commit $container user-management-frontend:latest
buildah rm $container

cd ..

# Containerd'ye import
echo "📤 Containerd'ye import ediliyor..."
buildah push user-management-backend:latest oci-archive:/tmp/backend.tar
buildah push user-management-frontend:latest oci-archive:/tmp/frontend.tar
sudo ctr -n k8s.io images import /tmp/backend.tar
sudo ctr -n k8s.io images import /tmp/frontend.tar

# Worker node'a gönder
echo "📤 Worker node'a gönderiliyor..."
scp /tmp/backend.tar root@192.168.0.233:/tmp/
scp /tmp/frontend.tar root@192.168.0.233:/tmp/
ssh root@192.168.0.233 'ctr -n k8s.io images import /tmp/backend.tar && ctr -n k8s.io images import /tmp/frontend.tar && rm -f /tmp/*.tar'

rm -f /tmp/backend.tar /tmp/frontend.tar

echo "✅ Build tamamlandı!"
sudo ctr -n k8s.io images ls | grep user-management
