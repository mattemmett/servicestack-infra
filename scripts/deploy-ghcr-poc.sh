#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:-}"
GHCR_IMAGE_ARG="${2:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_DIR="${STACK_DIR:-/opt/servicestack/poc-ghcr-hello}"
HOST_PORT="${HOST_PORT:-8080}"
GHCR_IMAGE="${GHCR_IMAGE_ARG:-${GHCR_IMAGE:-}}"
GHCR_REGISTRY="${GHCR_REGISTRY:-ghcr.io}"
GHCR_USERNAME="${GHCR_USERNAME:-}"
GHCR_TOKEN="${GHCR_TOKEN:-${GHCR_PAT:-}}"
AWS_PAGER="${AWS_PAGER:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Avoid interactive pager prompts (for example ':' waiting for 'q').
export AWS_PAGER=""

if [[ -z "$INSTANCE_ID" ]]; then
  echo "usage: $0 <instance-id>" >&2
  exit 1
fi

if [[ -z "$GHCR_IMAGE" ]]; then
  echo "GHCR_IMAGE must be set" >&2
  exit 1
fi

if [[ -z "$GHCR_USERNAME" || -z "$GHCR_TOKEN" ]]; then
  echo "GHCR_USERNAME and GHCR_TOKEN (or GHCR_PAT) must be set" >&2
  exit 1
fi

COMPOSE_B64=$(base64 < "$ROOT_DIR/poc/ghcr-hello/docker-compose.yml" | tr -d '\n')
NGINX_B64=$(base64 < "$ROOT_DIR/poc/ghcr-hello/nginx/default.conf" | tr -d '\n')
ENV_B64=$(printf 'GHCR_IMAGE=%s\nHOST_PORT=%s\n' "$GHCR_IMAGE" "$HOST_PORT" | base64 | tr -d '\n')
GHCR_TOKEN_B64=$(printf '%s\n' "$GHCR_TOKEN" | base64 | tr -d '\n')
ESCAPED_GHCR_USERNAME=$(printf '%q' "$GHCR_USERNAME")

REMOTE_COMMANDS=(
  "set -euo pipefail"
  "mkdir -p ${STACK_DIR}/nginx"
  "printf '%s' '${COMPOSE_B64}' | base64 -d > ${STACK_DIR}/docker-compose.yml"
  "printf '%s' '${NGINX_B64}' | base64 -d > ${STACK_DIR}/nginx/default.conf"
  "printf '%s' '${ENV_B64}' | base64 -d > ${STACK_DIR}/.env"
  "printf '%s' '${GHCR_TOKEN_B64}' | base64 -d > /tmp/ghcr-token"
  "echo '==> docker version'"
  "docker --version"
  "echo '==> docker compose version'"
  "docker compose version"
  "echo '==> docker login'"
  "set +e"
  "docker login ${GHCR_REGISTRY} -u ${ESCAPED_GHCR_USERNAME} --password-stdin < /tmp/ghcr-token > /tmp/ghcr-login.out 2> /tmp/ghcr-login.err"
  "LOGIN_STATUS=\$?"
  "echo \"docker login exit=\$LOGIN_STATUS\""
  "echo '--- ghcr login stderr ---'"
  "cat /tmp/ghcr-login.err >&2"
  "echo '--- ghcr login stdout ---'"
  "cat /tmp/ghcr-login.out"
  "if [ \"\$LOGIN_STATUS\" -ne 0 ]; then echo 'GHCR login failed' >&2; exit \"\$LOGIN_STATUS\"; fi"
  "rm -f /tmp/ghcr-token"
  "set -e"
  "cd ${STACK_DIR}"
  "export HOST_PORT=${HOST_PORT}"
  "echo '==> docker compose config'"
  "docker compose --env-file .env config > /tmp/docker-compose-config.out 2> /tmp/docker-compose-config.err"
  "echo '--- docker compose config stderr ---'"
  "cat /tmp/docker-compose-config.err >&2"
  "echo '--- docker compose config stdout ---'"
  "cat /tmp/docker-compose-config.out"
  "echo '==> docker pull image'"
  "set +e"
  "docker --debug pull ${GHCR_IMAGE} > /tmp/docker-pull.out 2> /tmp/docker-pull.err"
  "PULL_STATUS=\$?"
  "echo \"docker pull exit=\$PULL_STATUS\""
  "echo '--- docker pull stderr ---'"
  "cat /tmp/docker-pull.err >&2"
  "echo '--- docker pull stdout ---'"
  "cat /tmp/docker-pull.out"
  "echo '--- docker pull exit code ---'"
  "echo \"\$PULL_STATUS\""
  "if [ \"\$PULL_STATUS\" -ne 0 ]; then echo 'docker pull failed' >&2; exit \"\$PULL_STATUS\"; fi"
  "set -e"
  "echo '==> docker compose pull'"
  "docker compose --env-file .env pull"
  "echo '==> docker compose up'"
  "set +e"
  "docker compose --env-file .env up -d --remove-orphans > /tmp/docker-compose-up.out 2> /tmp/docker-compose-up.err"
  "UP_STATUS=\$?"
  "echo \"docker compose up exit=\$UP_STATUS\""
  "echo '--- docker compose up stderr ---'"
  "cat /tmp/docker-compose-up.err >&2"
  "echo '--- docker compose up stdout ---'"
  "cat /tmp/docker-compose-up.out"
  "if [ \"\$UP_STATUS\" -ne 0 ]; then echo 'docker compose up failed' >&2; echo '--- compose logs ---' >&2; docker compose --env-file .env logs --no-color >&2 || true; exit \"\$UP_STATUS\"; fi"
  "set -e"
  "echo '==> docker compose ps'"
  "docker compose --env-file .env ps"
  "echo '==> docker ps'"
  "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
  "echo '==> curl healthz'"
  "set +e"
  "curl -fsS http://localhost:${HOST_PORT}/healthz > /tmp/healthz.out 2> /tmp/healthz.err"
  "HEALTH_STATUS=\$?"
  "echo \"curl healthz exit=\$HEALTH_STATUS\""
  "echo '--- healthz stderr ---'"
  "cat /tmp/healthz.err >&2"
  "echo '--- healthz stdout ---'"
  "cat /tmp/healthz.out"
  "if [ \"\$HEALTH_STATUS\" -ne 0 ]; then echo 'health check failed' >&2; exit \"\$HEALTH_STATUS\"; fi"
  "set -e"
)

PARAMETERS_FILE=$(mktemp "${TMPDIR:-/tmp}/ssm-parameters.XXXXXX")
python3 - <<'PY' "$PARAMETERS_FILE" "${REMOTE_COMMANDS[@]}"
import json
import sys
path = sys.argv[1]
commands = sys.argv[2:]
with open(path, 'w', encoding='utf-8') as handle:
    json.dump({'commands': commands}, handle)
PY

echo "SSM parameters file: $PARAMETERS_FILE"
python3 - <<'PY' "$PARAMETERS_FILE"
import json
import sys
with open(sys.argv[1], encoding='utf-8') as handle:
    data = json.load(handle)
print(f"Remote command count: {len(data.get('commands', []))}")
PY

set +e
COMMAND_ID_OUTPUT=$(aws ssm send-command \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy GHCR hello POC" \
  --parameters "file://$PARAMETERS_FILE" \
  --query 'Command.CommandId' \
  --output text 2> /tmp/ssm-send.err)
SEND_STATUS=$?
set -e

if [[ $SEND_STATUS -ne 0 ]]; then
  echo "aws ssm send-command failed with exit $SEND_STATUS" >&2
  cat /tmp/ssm-send.err >&2
  exit "$SEND_STATUS"
fi

COMMAND_ID=$(printf '%s' "$COMMAND_ID_OUTPUT" | tr -d '\r\n')
echo "SSM command id: $COMMAND_ID"

set +e
aws ssm wait command-executed \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" 2> /tmp/ssm-wait.err
WAIT_EXIT=$?
set -e

echo "SSM wait exit code: $WAIT_EXIT"

if [[ $WAIT_EXIT -ne 0 ]]; then
  echo "aws ssm wait command-executed failed" >&2
  cat /tmp/ssm-wait.err >&2
  echo "Fetching SSM invocation output..." >&2
  aws ssm get-command-invocation \
    --no-cli-pager \
    --region "$AWS_REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
    --output json 2> /tmp/ssm-invocation.err || true
  if [[ -s /tmp/ssm-invocation.err ]]; then
    cat /tmp/ssm-invocation.err >&2
  fi
  exit "$WAIT_EXIT"
fi

aws ssm get-command-invocation \
  --no-cli-pager \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
  --output json
