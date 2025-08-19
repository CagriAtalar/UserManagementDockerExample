#!/usr/bin/env bash
set -euo pipefail

# Configuration (override via environment variables if needed)
REGISTRY_HOST="${REGISTRY_HOST:-192.168.0.146}"
REGISTRY_PORT="${REGISTRY_PORT:-5000}"
NAMESPACE="${NAMESPACE:-usermgmt}"
BACKEND_IMAGE_NAME="${BACKEND_IMAGE_NAME:-user-management-backend}"
FRONTEND_IMAGE_NAME="${FRONTEND_IMAGE_NAME:-user-management-frontend}"
FRONTEND_API_URL="${FRONTEND_API_URL:-.}"

REGISTRY="${REGISTRY_HOST}:${REGISTRY_PORT}"
BACKEND_IMAGE="${REGISTRY}/${BACKEND_IMAGE_NAME}:latest"
FRONTEND_IMAGE="${REGISTRY}/${FRONTEND_IMAGE_NAME}:latest"

log() { echo -e "\n[deploy-local] $*\n"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

choose_cli() {
  # Prefer nerdctl for containerd; fallback to docker if nerdctl not available
  if command -v nerdctl >/dev/null 2>&1; then
    CLI="nerdctl"
    log "Using nerdctl CLI (containerd)"
    return
  fi
  if command -v docker >/dev/null 2>&1 && systemctl is-active --quiet docker; then
    CLI="docker"
    log "Using docker CLI"
    return
  fi
  echo "Error: neither nerdctl nor active Docker daemon found. Install nerdctl or start Docker." >&2
  exit 1
}

ensure_repo_root() {
  if [[ ! -f "k8s/kustomization.yaml" ]]; then
    echo "Run this script from the repository root (k8s/kustomization.yaml not found)." >&2
    exit 1
  fi
}

ensure_registry() {
  : "${CLI:?internal: CLI must be set}"
  if curl -fsS "http://${REGISTRY}/v2/_catalog" >/dev/null 2>&1; then
    log "Local registry reachable at ${REGISTRY}"
    return
  fi

  log "Local registry not reachable. Starting registry:2 on ${REGISTRY_HOST}:${REGISTRY_PORT}"
  # Check by name using ps output - nerdctl/docker have different formats
  if [[ "${CLI}" == "nerdctl" ]]; then
    if ! ${CLI} ps -a --format "{{.Names}}" | grep -qx registry; then
      ${CLI} run -d --name registry -p "${REGISTRY_PORT}:5000" --restart=always registry:2 >/dev/null
    else
      ${CLI} start registry >/dev/null
    fi
  else
    if ! ${CLI} ps -a --format "{{.Names}}" | grep -qx registry; then
      ${CLI} run -d --name registry -p "${REGISTRY_PORT}:5000" --restart=always registry:2 >/dev/null
    else
      ${CLI} start registry >/dev/null
    fi
  fi

  # wait a moment
  sleep 2
  if ! curl -fsS "http://${REGISTRY}/v2/_catalog" >/dev/null 2>&1; then
    echo "Error: local registry at ${REGISTRY} is not reachable. Ensure daemon trusts insecure registries." >&2
    exit 1
  fi
}

build_and_push_images() {
  : "${CLI:?internal: CLI must be set}"
  log "Building backend image: ${BACKEND_IMAGE}"
  ${CLI} build -t "${BACKEND_IMAGE}" ./backend
  log "Pushing backend image to local registry"
  ${CLI} push "${BACKEND_IMAGE}"

  log "Building frontend image with REACT_APP_API_URL=${FRONTEND_API_URL}: ${FRONTEND_IMAGE}"
  ${CLI} build --build-arg "REACT_APP_API_URL=${FRONTEND_API_URL}" -t "${FRONTEND_IMAGE}" ./frontend
  log "Pushing frontend image to local registry"
  ${CLI} push "${FRONTEND_IMAGE}"
}

apply_manifests() {
  log "Creating namespace (if not exists): ${NAMESPACE}"
  kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${NAMESPACE}"

  log "Applying k8s manifests via kustomize"
  kubectl apply -k k8s

  log "Pointing deployments to local registry images"
  kubectl -n "${NAMESPACE}" set image deployment/backend backend="${BACKEND_IMAGE}" --record=true
  kubectl -n "${NAMESPACE}" set image deployment/frontend frontend="${FRONTEND_IMAGE}" --record=true

  log "Waiting for rollouts"
  kubectl -n "${NAMESPACE}" rollout status deploy/postgres
  kubectl -n "${NAMESPACE}" rollout status deploy/backend
  kubectl -n "${NAMESPACE}" rollout status deploy/frontend
}

show_endpoints() {
  log "Cluster resources in ${NAMESPACE}:"
  kubectl -n "${NAMESPACE}" get all

  log "Ingress service (if installed):"
  if kubectl get ns ingress-nginx >/dev/null 2>&1; then
    kubectl -n ingress-nginx get svc ingress-nginx-controller || true
  else
    echo "ingress-nginx namespace not found. If you use Ingress, install NGINX Ingress Controller first." >&2
  fi
}

main() {
  # We only require curl/kubectl; container CLI decided dynamically
  require_cmd kubectl
  require_cmd curl
  ensure_repo_root

  log "Using settings:\n  REGISTRY=${REGISTRY}\n  NAMESPACE=${NAMESPACE}\n  BACKEND_IMAGE=${BACKEND_IMAGE}\n  FRONTEND_IMAGE=${FRONTEND_IMAGE}\n  FRONTEND_API_URL=${FRONTEND_API_URL}"

  choose_cli
  ensure_registry
  build_and_push_images
  apply_manifests
  show_endpoints

  log "Done. If pods fail to pull images with ImagePullBackOff, ensure all nodes trust the insecure registry ${REGISTRY}.\n\nFor containerd nodes, run:\n  sudo mkdir -p /etc/containerd/certs.d/${REGISTRY}\n  echo 'server = \"http://${REGISTRY}\"' | sudo tee /etc/containerd/certs.d/${REGISTRY}/hosts.toml\n  sudo systemctl restart containerd\n\nFor Docker nodes, add to daemon.json and restart docker."
}

main "$@"


