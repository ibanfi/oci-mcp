#!/usr/bin/env bash

set -u

# Configuration
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-arvenis}"
REGISTRY="${REGISTRY:-docker.io}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create build logs directory
mkdir -p .push-logs
summary_file=.push-logs/image-push-summary.txt
: > "$summary_file"
status=0

# List of OCI MCP server directories to push
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

echo "DockerHub Push Script"
echo "===================="
echo "Registry: $REGISTRY"
echo "Username: $DOCKERHUB_USERNAME"
echo ""

# Function to tag and push image
tag_and_push_image() {
  local server="$1"
  local dir="src/$server"
  
  if [ ! -f "$dir/pyproject.toml" ]; then
    echo -e "${YELLOW}SKIP${NC}|$server|File not found: $dir/pyproject.toml" | tee -a "$summary_file"
    return 0
  fi
  
  # Extract name and version from pyproject.toml
  local name=$(awk -F ' = ' '/^name = / {gsub(/"/, "", $2); print $2; exit}' "$dir/pyproject.toml")
  local version=$(awk -F ' = ' '/^version = / {gsub(/"/, "", $2); print $2; exit}' "$dir/pyproject.toml")
  
  if [ -z "$name" ] || [ -z "$version" ]; then
    echo -e "${RED}FAIL${NC}|$server|Could not extract name or version" | tee -a "$summary_file"
    return 1
  fi
  
  # Source image name and target image name
  local source_image="$name:$version"
  local target_image="$DOCKERHUB_USERNAME/$server:$version"
  local target_latest="$DOCKERHUB_USERNAME/$server:latest"
  
  echo ""
  echo -e "${YELLOW}Processing${NC}: $server"
  echo "  Source: $source_image"
  echo "  Target: $target_image"
  
  # Check if source image exists
  if ! docker image inspect "$source_image" &>/dev/null; then
    echo -e "${RED}FAIL${NC}|$server|Source image not found: $source_image" | tee -a "$summary_file"
    status=1
    return 1
  fi
  
  # Tag the image
  if docker tag "$source_image" "$target_image"; then
    echo -e "${GREEN}✓${NC} Tagged: $source_image -> $target_image"
  else
    echo -e "${RED}✗${NC} Failed to tag image"
    echo -e "${RED}FAIL${NC}|$server|Failed to tag $source_image -> $target_image" | tee -a "$summary_file"
    status=1
    return 1
  fi
  
  # Tag as latest
  if docker tag "$source_image" "$target_latest"; then
    echo -e "${GREEN}✓${NC} Tagged: $source_image -> $target_latest"
  else
    echo -e "${RED}✗${NC} Failed to tag image as latest"
    echo -e "${RED}FAIL${NC}|$server|Failed to tag $source_image -> $target_latest" | tee -a "$summary_file"
    status=1
    return 1
  fi
  
  # Push the versioned image
  echo "Pushing $target_image..."
  if docker push "$target_image"; then
    echo -e "${GREEN}✓${NC} Pushed: $target_image"
  else
    echo -e "${RED}✗${NC} Failed to push $target_image"
    echo -e "${RED}FAIL${NC}|$server|Failed to push $target_image" | tee -a "$summary_file"
    status=1
    return 1
  fi
  
  # Push the latest image
  echo "Pushing $target_latest..."
  if docker push "$target_latest"; then
    echo -e "${GREEN}✓${NC} Pushed: $target_latest"
    echo -e "${GREEN}OK${NC}|$server|$target_image|$target_latest" | tee -a "$summary_file"
  else
    echo -e "${RED}✗${NC} Failed to push $target_latest"
    echo -e "${RED}FAIL${NC}|$server|Failed to push $target_latest" | tee -a "$summary_file"
    status=1
    return 1
  fi
}

# Process all servers
for server in "${SERVERS[@]}"; do
  tag_and_push_image "$server"
done

echo ""
echo "===================="
echo "Push Summary"
echo "===================="
cat "$summary_file"
echo ""

if [ $status -eq 0 ]; then
  echo -e "${GREEN}All images pushed successfully!${NC}"
else
  echo -e "${RED}Some images failed to push. Check $summary_file for details.${NC}"
fi

exit $status
