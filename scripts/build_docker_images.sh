#!/usr/bin/env bash

set -u

mkdir -p .build-logs
summary_file=.build-logs/image-build-summary.txt
: > "$summary_file"
status=0

build_pyproject_image() {
  dir="$1"
  file="$2"
  name=$(awk -F ' = ' '/^name = / {gsub(/"/, "", $2); print $2; exit}' "$dir/pyproject.toml")
  version=$(awk -F ' = ' '/^version = / {gsub(/"/, "", $2); print $2; exit}' "$dir/pyproject.toml")
  log_file=".build-logs/$(basename "$dir").log"

  echo "BUILD $dir -> $name:$version"
  if docker build -f "$dir/$file" -t "$name:$version" -t "$name:latest" "$dir" >"$log_file" 2>&1; then
    echo "OK|$dir|$name:$version|$name:latest|$log_file" | tee -a "$summary_file"
  else
    echo "FAIL|$dir|$name:$version|$name:latest|$log_file" | tee -a "$summary_file"
    status=1
  fi
}

build_java_image() {
  dir="$1"
  file="$2"
  artifact=$(grep -m1 -oE '<artifactId>[^<]+' "$dir/pom.xml" | sed 's/<artifactId>//')
  version=$(grep -m1 -oE '<version>[^<]+' "$dir/pom.xml" | sed 's/<version>//')
  log_file=".build-logs/$(basename "$dir").log"

  echo "BUILD $dir -> $artifact:$version"
  if docker build -f "$dir/$file" -t "$artifact:$version" -t "$artifact:latest" "$dir" >"$log_file" 2>&1; then
    echo "OK|$dir|$artifact:$version|$artifact:latest|$log_file" | tee -a "$summary_file"
  else
    echo "FAIL|$dir|$artifact:$version|$artifact:latest|$log_file" | tee -a "$summary_file"
    status=1
  fi
}

for dir in \
  src/oci-api-mcp-server \
  src/oci-cloud-guard-mcp-server \
  src/oci-cloud-mcp-server \
  src/oci-compute-instance-agent-mcp-server \
  src/oci-compute-mcp-server \
  src/oci-identity-mcp-server \
  src/oci-logging-mcp-server \
  src/oci-migration-mcp-server \
  src/oci-monitoring-mcp-server \
  src/oci-network-load-balancer-mcp-server \
  src/oci-networking-mcp-server \
  src/oci-object-storage-mcp-server \
  src/oci-registry-mcp-server \
  src/oci-resource-search-mcp-server \
  src/oci-usage-mcp-server \
  src/oci-pricing-mcp-server \
  src/oracle-db-doc-mcp-server
do
  if [ -f "$dir/pyproject.toml" ]; then
    if [ -f "$dir/Containerfile" ]; then
      build_pyproject_image "$dir" Containerfile
    elif [ -f "$dir/Dockerfile" ]; then
      build_pyproject_image "$dir" Dockerfile
    fi
  fi
done

build_java_image src/oracle-db-mcp-java-toolkit Dockerfile

echo "---" | tee -a "$summary_file"
awk -F '|' 'BEGIN { ok = 0; fail = 0 } /^OK\|/ { ok++ } /^FAIL\|/ { fail++ } END { printf("TOTAL_OK=%d\nTOTAL_FAIL=%d\n", ok, fail) }' "$summary_file" | tee -a "$summary_file"

exit "$status"