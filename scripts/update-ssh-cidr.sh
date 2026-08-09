#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Create it first from .env.local.example"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not found"
  exit 1
fi

CURRENT_IP="$(curl -fsSL https://api.ipify.org)"
NEW_CIDR="${CURRENT_IP}/32"
NEW_EXPORT="export TF_VAR_ssh_cidr_blocks='[\"${NEW_CIDR}\"]'"

if grep -q '^export TF_VAR_ssh_cidr_blocks=' "$ENV_FILE"; then
  TMP_FILE="${ENV_FILE}.tmp"
  awk -v replacement="$NEW_EXPORT" '
    BEGIN { replaced = 0 }
    {
      if ($0 ~ /^export TF_VAR_ssh_cidr_blocks=/) {
        print replacement
        replaced = 1
      } else {
        print $0
      }
    }
    END {
      if (replaced == 0) {
        print replacement
      }
    }
  ' "$ENV_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$ENV_FILE"
else
  printf "\n%s\n" "$NEW_EXPORT" >> "$ENV_FILE"
fi

echo "Updated TF_VAR_ssh_cidr_blocks to ${NEW_CIDR} in $ENV_FILE"
echo "Next: source scripts/load-local-env.sh && tofu -chdir=environments/prod plan"
