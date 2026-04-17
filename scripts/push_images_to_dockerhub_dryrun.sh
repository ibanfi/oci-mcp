#!/usr/bin/env bash

set -u

# Configuration
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-arvenis}"
REGISTRY="${REGISTRY:-docker.io}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# List of OCI MCP server directories
SERVERS=(
  "oci-api-mcp-server"
  "oci-cloud-guard-mcp-server"
  "oci-cloud-mcp-server"
  "oci-compute-instance-agent-mcp-server"
  "oci-compute-mcp-server"
  "oci-database-mcp-server"
  "oci-faaas-mcp-server"
  "oci-identity-mcp-server"
  "oci-limits-mcp-server"
  "oci-load-balancer-mcp-server"
  "oci-logging-mcp-server"
  "oci-migration-mcp-server"
  "oci-monitoring-mcp-server"
  "oci-network-load-balancer-mcp-server"
  "oci-networking-mcp-server"
  "oci-object-storage-mcp-server"
  "oci-pricing-mcp-server"
  "oci-recovery-mcp-server"
  "oci-registry-mcp-server"
  "oci-resource-search-mcp-server"
  "oci-usage-mcp-server"
)

echo "DockerHub Tag & Push DRY RUN"
echo "============================"
echo "Registry: $REGISTRY"
echo "Username: $DOCKERHUB_USERNAME"
echo ""
echo -e "${BLUE}This script shows what WOULD be tagged and pushed (no actual changes)${NC}"
echo ""

# Function to show what would happen
show_tag_and_push() {
  local server="$1"
  local dir="src/$server"
  
  if [ ! -f "$dir/pyproject.toml" ]; then
    echo -e "${YELLOW}SKIP${NC}: $server (pyproject.toml not found)"
    return 0
  fi
  
  # Extract name and version from pyproject.toml
  local name=$(awk -F ' = ' '/^name = / {gsub(/"/, "", $2); print $2; exit}' "$dir/pyproject.toml")
  local version=$(awk -F ' = ' '/^version = / {gsub(/"/, "", $2); print $2; exit}' "$dir/pyproject.toml")
  
  if [ -z "$name" ] || [ -z "$version" ]; then
    echo -e "${RED}FAIL${NC}: $server (could not extract name or version)"
    return 1
  fi
  
  # Source image name and target image name
  local source_image="$name:$version"
  local target_image="$DOCKERHUB_USERNAME/$server:$version"
  local target_latest="$DOCKERHUB_USERNAME/$server:latest"
  
  echo -e "${GREEN}✓${NC} $server"
  echo "  Version: $version"
  echo "  Commands:"
  echo "    docker tag $source_image $target_image"
  echo "    docker tag $source_image $target_latest"
  echo "    docker push $target_image"
  echo "    docker push $target_latest"
  echo ""
}

# Process all servers
for server in "${SERVERS[@]}"; do
  show_tag_and_push "$server"
done

echo "============================"
echo -e "${BLUE}To execute the actual push, run:${NC}"
echo "  ./scripts/push_images_to_dockerhub.sh"
echo ""
echo -e "${YELLOW}Make sure you are logged in to Docker Hub:${NC}"
echo "  docker login -u <username>"
