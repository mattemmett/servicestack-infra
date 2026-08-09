# GHCR PoC validation

## Purpose

This runbook captures the proof-of-concept validation for deploying a private container image from GHCR onto the production EC2 Docker host through the infra-managed SSM path.

The goal is not to define the long-term app build pipeline. The goal is to verify the infrastructure contract:

- the EC2 host can receive an SSM deploy command,
- Docker and Compose are available on the host,
- the host can authenticate to GHCR,
- the host can pull a private image,
- the compose stack can start,
- and the health endpoint responds.

## Ownership boundary

- Infra repo: host readiness, Docker runtime, SSM deployment path, network and IAM assumptions.
- App repo: image build, image tagging, image push to GHCR, and app-specific runtime configuration.

## Verified outcome

This PoC was validated successfully with the following behavior:

- the deploy script completed with SSM status `Success`,
- the compose stack started successfully,
- the health endpoint returned `ok`.

## Local build and push example

Use this from a repository that owns the application image:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t ghcr.io/<owner>/<image>:latest \
  ./path/to/app/context
```

For this repo’s temporary PoC, the image used was:

```bash
ghcr.io/mattemmett/servicestack-ghcr-hello:latest
```

## Deploy to the EC2 host

From the infra repo, deploy the PoC stack with the image reference supplied explicitly:

```bash
GHCR_IMAGE=ghcr.io/mattemmett/servicestack-ghcr-hello:latest \
GHCR_USERNAME=<github-username-that-owns-the-pat> \
GHCR_TOKEN=<ghcr-pat> \
bash scripts/deploy-ghcr-poc.sh i-0eec1257722b6b1c9
```

Notes:

- `GHCR_TOKEN` and `GHCR_PAT` are both accepted by the deploy scripts.
- `GHCR_USERNAME` should be the GitHub username associated with that PAT.

## Health check

After deployment, verify the remote health endpoint from the host through SSM:

```bash
aws ssm send-command \
  --region us-east-1 \
  --instance-ids i-0eec1257722b6b1c9 \
  --document-name AWS-RunShellScript \
  --comment "Check GHCR hello health" \
  --parameters 'commands=["curl -fsS http://127.0.0.1:8080/healthz"]'
```

Then retrieve the invocation output:

```bash
aws ssm get-command-invocation \
  --region us-east-1 \
  --command-id <command-id> \
  --instance-id i-0eec1257722b6b1c9 \
  --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
  --output json
```

Expected success output:

```json
{
  "Status": "Success",
  "Stdout": "ok\n",
  "Stderr": ""
}
```

## Follow-up test ideas

Use these for future validation once the app repo owns the image pipeline:

1. change the image tag and redeploy,
2. verify rollback to the previous tag,
3. test a new image with a different architecture or runtime change,
4. validate that registry credentials rotate cleanly without changing infra,
5. confirm the deployment flow works from a real app-repo workflow rather than this temporary PoC script.
