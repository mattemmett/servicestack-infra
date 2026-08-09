#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Active IaC only. The legacy snapshot is intentionally excluded.
INCLUDE_GLOB='*.tf'
EXCLUDE_GLOBS=(
  'servicestack-infrastructure/**'
  '**/.terraform/**'
  '**/terraform.tfstate*'
)

RG_EXCLUDES=()
for g in "${EXCLUDE_GLOBS[@]}"; do
  RG_EXCLUDES+=(--glob "!$g")
done

if command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL="rg"
elif command -v grep >/dev/null 2>&1; then
  SEARCH_TOOL="grep"
else
  fail "Neither ripgrep nor grep is available. Cannot validate exports boundary."
fi

search_pattern() {
  local pattern="$1"
  local output_file="$2"

  if [[ "$SEARCH_TOOL" == "rg" ]]; then
    if rg -n --glob "$INCLUDE_GLOB" "${RG_EXCLUDES[@]}" "$pattern" > "$output_file"; then
      return 0
    fi
    return 1
  fi

  local exclude_args=()
  for g in "${EXCLUDE_GLOBS[@]}"; do
    exclude_args+=(--exclude-dir="${g%%/**}")
  done

  if grep -RInE --include "$INCLUDE_GLOB" "${exclude_args[@]}" "$pattern" . > "$output_file"; then
    return 0
  fi
  return 1
}

fail() {
  echo "[exports-boundary] FAIL: $1" >&2
  exit 1
}

# 1) Hard-stop any literal producer bucket references in active Terraform.
if search_pattern 'servicestack-exports-warehouse-prod' /tmp/exports-boundary-literal.txt; then
  echo "[exports-boundary] Found forbidden literal exports bucket reference(s):"
  cat /tmp/exports-boundary-literal.txt
  fail "Use contract inputs (variables, SSM, or remote state), never literal producer bucket names in active Terraform."
fi

# 2) Hard-stop any S3 bucket resources labeled as exports/warehouse.
if search_pattern 'resource\s+"aws_s3_bucket(_[a-z_]+)?"\s+"[^"]*(exports|warehouse)[^"]*"' /tmp/exports-boundary-resource-label.txt; then
  echo "[exports-boundary] Found forbidden S3 bucket resource label(s):"
  cat /tmp/exports-boundary-resource-label.txt
  fail "Producer-owned exports buckets must never be created or managed in servicestack-infra."
fi

# 3) Hard-stop any import blocks targeting exports/warehouse buckets.
if search_pattern '(import\s*\{|to\s*=\s*aws_s3_bucket|id\s*=\s*"[^"]*(exports|warehouse)[^"]*")' /tmp/exports-boundary-imports.txt; then
  # Filter down to files that contain both import block and exports/warehouse hints.
  MATCHED_FILES=$(awk -F: '{print $1}' /tmp/exports-boundary-imports.txt | sort -u)
  if [[ -n "$MATCHED_FILES" ]]; then
    echo "[exports-boundary] Potential forbidden import ownership pattern(s):"
    echo "$MATCHED_FILES"
    fail "Do not import producer-owned exports buckets into this state."
  fi
fi

echo "[exports-boundary] PASS: no producer-owned exports bucket ownership patterns found in active Terraform."
