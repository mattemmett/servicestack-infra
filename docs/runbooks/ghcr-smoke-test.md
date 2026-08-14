# GHCR Smoke Test

Purpose: prove that the current prod EC2 host can authenticate to GHCR, pull a private image, and run it through the SSM deployment path.

## Inputs

- Host instance ID: current prod host from Terraform state.
- `GHCR_IMAGE`: full image reference, for example `ghcr.io/mattemmett/servicestack-ghcr-hello:latest`.
- `GHCR_USERNAME`: GitHub username that owns the token used for package pull.
- `GHCR_TOKEN`: token with package read access (`GHCR_PAT` is also accepted).

Token requirements:

- For publishing: token needs `write:packages` and repo access for this repository.
- For host pull: token needs `read:packages` for the target package.

## Publish Image

Preferred path:

1. Run the `Publish GHCR Hello` workflow.
2. Confirm the image appears in GHCR.

Repository secrets required for deploy workflow:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `PROD_HOST_INSTANCE_ID`
- `GHCR_IMAGE`
- `GHCR_USERNAME`
- `GHCR_TOKEN`

Optional local path:

1. Build the image locally.
2. Log in to GHCR.
3. Push the image manually.

## Deploy To Host

```bash
AWS_REGION=us-east-1 \
GHCR_IMAGE=ghcr.io/mattemmett/servicestack-ghcr-hello:latest \
GHCR_USERNAME=your-github-user \
GHCR_TOKEN=your-ghcr-token \
bash scripts/deploy-ghcr-poc.sh i-0eec1257722b6b1c9
```

## Verify

1. Confirm the SSM command returns success.
2. Confirm `docker compose ps` shows both containers running.
3. Confirm `curl -fsS http://localhost/healthz` returns `ok`.
4. Open the host public IP and confirm the page says `ServiceStack GHCR Hello`.

## Notes

- This is the registry-auth proof step between the public hello-world demo and the real ServiceStack runtime.
- Historical note: this POC predates the CloudFront-backed console rollout. Do not use it to change the current app compose runtime.
