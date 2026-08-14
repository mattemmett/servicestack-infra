# Hello World Smoke Test

Purpose: prove that the current prod EC2 host can deploy and serve a simple compose-based workload through the same SSM path we will use for ServiceStack.

## What This Uses

- The current prod EC2 Docker host managed by this repo.
- The existing POC in `poc/web-hello`.
- The existing SSM deploy helper in `scripts/deploy-poc-demo.sh`.

## Expected Result

- `nginxdemos/hello:plain-text` is pulled on the host.
- Nginx serves the POC on port 80.
- `http://localhost/healthz` returns `ok` on the host.
- The public host endpoint serves the hello-world page.

## Preconditions

1. Run from the root of `servicestack-infra` or adjust paths accordingly.
2. Confirm the prod host instance ID from Terraform state or AWS output.
3. Confirm the host is the active working bridge and not a replacement target.

## Deploy

```bash
AWS_REGION=us-east-1 bash scripts/deploy-poc-demo.sh i-0eec1257722b6b1c9
```

If the instance ID changes, use the current value from `environments/prod` outputs.

## Verify

1. Check the SSM command output for `docker compose ps`.
2. Confirm the health check succeeded.
3. Visit the host public IP or routed hostname in a browser.
4. Confirm the page content is the Nginx hello demo, not an error page.

## Roll Back

1. Re-run the deploy helper after restoring the prior compose files in `poc/web-hello` if needed.
2. Confirm the old stack comes back up cleanly.

## Notes

- This smoke test is intentionally simple and uses a public demo image.
- It is the first validation step before moving to a private registry image and then the real ServiceStack runtime.
- Historical note: this POC predates the current CloudFront-backed app runtime. Do not use it to manage the current production compose stack.
