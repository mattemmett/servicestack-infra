#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_DIR="${STACK_DIR:-/opt/servicestack/poc-web-hello}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -z "$INSTANCE_ID" ]]; then
  echo "usage: $0 <instance-id>" >&2
  exit 1
fi

COMPOSE_B64=$(base64 < "$ROOT_DIR/poc/web-hello/docker-compose.yml" | tr -d '\n')
NGINX_B64=$(base64 < "$ROOT_DIR/poc/web-hello/nginx/default.conf" | tr -d '\n')

REMOTE_COMMANDS=(
  "set -euxo pipefail"
  "mkdir -p ${STACK_DIR}/nginx"
  "printf '%s' '${COMPOSE_B64}' | base64 -d > ${STACK_DIR}/docker-compose.yml"
  "printf '%s' '${NGINX_B64}' | base64 -d > ${STACK_DIR}/nginx/default.conf"
  "cd ${STACK_DIR}"
  "docker compose pull"
  "docker compose up -d --remove-orphans"
  "docker compose ps"
  "curl -fsS http://localhost/healthz"
)

COMMAND_LIST=$(printf '"%s",' "${REMOTE_COMMANDS[@]}")
COMMAND_LIST="[${COMMAND_LIST%,}]"

COMMAND_ID=$(aws ssm send-command \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy web hello POC" \
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
