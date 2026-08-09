#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
APP_DIR="${APP_DIR:-/opt/servicestack/app}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
ENV_FILE="${ENV_FILE:-.env}"
IMAGE_TAG="${IMAGE_TAG:-}"
GHCR_REGISTRY="${GHCR_REGISTRY:-ghcr.io}"
GHCR_USERNAME="${GHCR_USERNAME:-}"
GHCR_TOKEN="${GHCR_TOKEN:-${GHCR_PAT:-}}"

# Avoid interactive pager prompts (for example ':' waiting for 'q').
export AWS_PAGER=""

if [[ -z "$INSTANCE_ID" ]]; then
  echo "usage: $0 <instance-id>" >&2
  exit 1
fi

REMOTE_COMMANDS=(
  "set -euo pipefail"
  "mkdir -p ${APP_DIR}"
  "cd ${APP_DIR}"
)

if [[ -n "$IMAGE_TAG" ]]; then
  REMOTE_COMMANDS+=("export IMAGE_TAG=${IMAGE_TAG}")
fi

if [[ -n "$GHCR_USERNAME" && -n "$GHCR_TOKEN" ]]; then
  ESCAPED_GHCR_USERNAME=$(printf '%q' "$GHCR_USERNAME")
  ESCAPED_GHCR_TOKEN=$(printf '%q' "$GHCR_TOKEN")
  REMOTE_COMMANDS+=("printf %s ${ESCAPED_GHCR_TOKEN} | docker login ${GHCR_REGISTRY} -u ${ESCAPED_GHCR_USERNAME} --password-stdin")
fi

REMOTE_COMMANDS+=(
  "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} pull"
  "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} up -d --remove-orphans"
  "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} ps"
)

COMMAND_LIST=$(printf '"%s",' "${REMOTE_COMMANDS[@]}")
COMMAND_LIST="[${COMMAND_LIST%,}]"

COMMAND_ID=$(aws ssm send-command \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy compose stack" \
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
