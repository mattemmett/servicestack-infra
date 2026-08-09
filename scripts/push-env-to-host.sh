#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:-}"
ENV_SOURCE_FILE="${2:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
APP_DIR="${APP_DIR:-/opt/servicestack/app}"
ENV_TARGET_FILE="${ENV_TARGET_FILE:-.env}"

# Avoid interactive pager prompts from AWS CLI output.
export AWS_PAGER=""

if [[ -z "$INSTANCE_ID" || -z "$ENV_SOURCE_FILE" ]]; then
  echo "usage: $0 <instance-id> <local-env-file>" >&2
  exit 1
fi

if [[ ! -f "$ENV_SOURCE_FILE" ]]; then
  echo "env file not found: $ENV_SOURCE_FILE" >&2
  exit 1
fi

ENV_B64=$(base64 < "$ENV_SOURCE_FILE" | tr -d '\n')

REMOTE_COMMANDS=(
  "set -euo pipefail"
  "mkdir -p ${APP_DIR}"
  "printf '%s' '${ENV_B64}' | base64 -d > ${APP_DIR}/${ENV_TARGET_FILE}"
  "chmod 600 ${APP_DIR}/${ENV_TARGET_FILE}"
  "ls -l ${APP_DIR}/${ENV_TARGET_FILE}"
)

COMMAND_LIST=$(printf '"%s",' "${REMOTE_COMMANDS[@]}")
COMMAND_LIST="[${COMMAND_LIST%,}]"

COMMAND_ID=$(aws ssm send-command \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Upload runtime env file" \
  --parameters "commands=${COMMAND_LIST}" \
  --query 'Command.CommandId' \
  --output text)

aws ssm wait command-executed \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID"

aws ssm get-command-invocation \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
  --output json
