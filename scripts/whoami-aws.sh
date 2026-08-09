#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_LOADER="$ROOT_DIR/scripts/load-local-env.sh"

if [[ -f "$ENV_LOADER" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_LOADER"
fi

if [[ "${AWS_PROFILE:-}" == "" || "${AWS_PROFILE:-}" == "REPLACE_WITH_YOUR_PROFILE" ]]; then
  echo "AWS_PROFILE is not set to a real profile name."
  echo "Update .env.local and set AWS_PROFILE to a valid profile from ~/.aws/credentials or ~/.aws/config."
  exit 1
fi

if [[ "${AWS_REGION:-}" == "" && "${AWS_DEFAULT_REGION:-}" == "" ]]; then
  echo "AWS region is not set. Set AWS_REGION or AWS_DEFAULT_REGION in .env.local."
  exit 1
fi

echo "AWS preflight checks"
echo "  profile: ${AWS_PROFILE}"
echo "  region : ${AWS_REGION:-${AWS_DEFAULT_REGION}}"

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI not found in PATH."
  exit 1
fi

echo "\nCaller identity:"
aws sts get-caller-identity --output table

echo "\nValidation checks:"
aws configure list
