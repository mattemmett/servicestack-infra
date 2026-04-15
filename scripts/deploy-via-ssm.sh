#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
APP_DIR="${APP_DIR:-/opt/servicestack/app}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
ENV_FILE="${ENV_FILE:-.env}"
IMAGE_TAG="${IMAGE_TAG:-}"

if [[ -z "$INSTANCE_ID" ]]; then
  echo "usage: $0 <instance-id>" >&2
  exit 1
fi

REMOTE_COMMANDS=(
  "set -euxo pipefail"
  "mkdir -p ${APP_DIR}"
  "cd ${APP_DIR}"
)

if [[ -n "$IMAGE_TAG" ]]; then
  REMOTE_COMMANDS+=("export IMAGE_TAG=${IMAGE_TAG}")
fi

REMOTE_COMMANDS+=(
  "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} pull"
  "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} up -d --remove-orphans"
  "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} ps"
)

COMMAND_LIST=$(printf '"%s",' "${REMOTE_COMMANDS[@]}")
COMMAND_LIST="[${COMMAND_LIST%,}]"

COMMAND_ID=$(aws ssm send-command \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy compose stack" \
  --parameters "commands=${COMMAND_LIST}" \
  --query 'Command.CommandId' \
  --output text)

aws ssm wait command-executed \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID"

aws ssm get-command-invocation \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
  --output json
