# DockerHub Push Scripts

This directory contains scripts for tagging and pushing OCI MCP server Docker images to DockerHub.

## Scripts

### `push_images_to_dockerhub.sh`
Main script to tag and push all OCI MCP server images to DockerHub.

**Features:**
- Extracts image name and version from each service's `pyproject.toml`
- Tags images with DockerHub username (configurable)
- Pushes both versioned and latest tags
- Creates detailed push summary in `.push-logs/image-push-summary.txt`
- Color-coded output for easy tracking

**Prerequisites:**
1. Build all OCI MCP server Docker images first:
   ```bash
   ./scripts/build_docker_images.sh
   ```

2. Log in to Docker Hub:
   ```bash
   docker login -u <your-dockerhub-username>
   ```

**Usage:**
```bash
# Using default username (arvenis)
./scripts/push_images_to_dockerhub.sh

# Using custom DockerHub username
DOCKERHUB_USERNAME=myusername ./scripts/push_images_to_dockerhub.sh
```

**Environment Variables:**
- `DOCKERHUB_USERNAME` - DockerHub username (default: `arvenis`)
- `REGISTRY` - Docker registry URL (default: `docker.io`)

**Output:**
The script creates a summary file at `.push-logs/image-push-summary.txt` with the status of each push operation:
```
OK|service-name|docker.io/username/service:version|docker.io/username/service:latest
FAIL|service-name|Error message
SKIP|service-name|Reason
```

### `push_images_to_dockerhub_dryrun.sh`
Dry-run version showing what would be tagged and pushed without making actual changes.

**Usage:**
```bash
./scripts/push_images_to_dockerhub_dryrun.sh
```

## Example Workflow

1. **Build all images:**
   ```bash
   ./scripts/build_docker_images.sh
   ```

2. **Verify what will be pushed (dry-run):**
   ```bash
   ./scripts/push_images_to_dockerhub_dryrun.sh
   ```

3. **Login to DockerHub:**
   ```bash
   docker login -u arvenis
   ```

4. **Push all images:**
   ```bash
   ./scripts/push_images_to_dockerhub.sh
   ```

5. **Check results:**
   ```bash
   cat .push-logs/image-push-summary.txt
   ```

## Services Pushed

The following OCI MCP server images are pushed:
- oci-api-mcp-server
- oci-cloud-guard-mcp-server
- oci-cloud-mcp-server
- oci-compute-instance-agent-mcp-server
- oci-compute-mcp-server
- oci-database-mcp-server
- oci-faaas-mcp-server
- oci-identity-mcp-server
- oci-limits-mcp-server
- oci-load-balancer-mcp-server
- oci-logging-mcp-server
- oci-migration-mcp-server
- oci-monitoring-mcp-server
- oci-network-load-balancer-mcp-server
- oci-networking-mcp-server
- oci-object-storage-mcp-server
- oci-pricing-mcp-server
- oci-recovery-mcp-server
- oci-registry-mcp-server
- oci-resource-search-mcp-server
- oci-usage-mcp-server

## Troubleshooting

**Authentication failed:**
```bash
docker login -u <your-username>
```

**Source image not found:**
Ensure you've run `./scripts/build_docker_images.sh` first to build all images.

**Permission denied:**
Make sure the scripts are executable:
```bash
chmod +x scripts/push_images_to_dockerhub*.sh
```

**View detailed logs:**
```bash
cat .push-logs/image-push-summary.txt
```
