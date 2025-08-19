#!/usr/bin/env bash
set -euo pipefail

# Configuration
REGISTRY_HOST="${REGISTRY_HOST:-192.168.0.146}"
REGISTRY_PORT="${REGISTRY_PORT:-5000}"
WORKER_NODE="${WORKER_NODE:-192.168.0.233}"

REGISTRY="${REGISTRY_HOST}:${REGISTRY_PORT}"

log() { echo -e "\n[setup-containerd] $*\n"; }

setup_containerd_registry() {
  local target_host="$1"
  local is_remote="$2"
  
  if [[ "$is_remote" == "true" ]]; then
    log "Setting up containerd insecure registry on remote host: $target_host"
    ssh "cagri@$target_host" "
      sudo mkdir -p /etc/containerd/certs.d/${REGISTRY} && \
      echo 'server = \"http://${REGISTRY}\"' | sudo tee /etc/containerd/certs.d/${REGISTRY}/hosts.toml && \
      echo '[host.\"http://${REGISTRY}\"]' | sudo tee -a /etc/containerd/certs.d/${REGISTRY}/hosts.toml && \
      echo '  capabilities = [\"pull\", \"resolve\"]' | sudo tee -a /etc/containerd/certs.d/${REGISTRY}/hosts.toml && \
      sudo systemctl restart containerd && \
      sudo systemctl status containerd --no-pager -l
    "
  else
    log "Setting up containerd insecure registry on local host: $target_host"
    sudo mkdir -p "/etc/containerd/certs.d/${REGISTRY}"
    echo "server = \"http://${REGISTRY}\"" | sudo tee "/etc/containerd/certs.d/${REGISTRY}/hosts.toml"
    echo "[host.\"http://${REGISTRY}\"]" | sudo tee -a "/etc/containerd/certs.d/${REGISTRY}/hosts.toml"
    echo "  capabilities = [\"pull\", \"resolve\"]" | sudo tee -a "/etc/containerd/certs.d/${REGISTRY}/hosts.toml"
    sudo systemctl restart containerd
    sudo systemctl status containerd --no-pager -l
  fi
}

test_registry_access() {
  local target_host="$1"
  local is_remote="$2"
  
  if [[ "$is_remote" == "true" ]]; then
    log "Testing registry access from remote host: $target_host"
    ssh "cagri@$target_host" "curl -fsS http://${REGISTRY}/v2/_catalog"
  else
    log "Testing registry access from local host: $target_host"
    curl -fsS "http://${REGISTRY}/v2/_catalog"
  fi
}

main() {
  log "Setting up containerd insecure registry configuration"
  log "Registry: ${REGISTRY}"
  log "Master: ${REGISTRY_HOST}"
  log "Worker: ${WORKER_NODE}"

  # Setup on master (local)
  setup_containerd_registry "${REGISTRY_HOST}" "false"
  test_registry_access "${REGISTRY_HOST}" "false"

  # Setup on worker (remote)
  setup_containerd_registry "${WORKER_NODE}" "true"
  test_registry_access "${WORKER_NODE}" "true"

  log "Done. Both nodes should now be able to pull from the insecure registry at ${REGISTRY}"
}

main "$@"
