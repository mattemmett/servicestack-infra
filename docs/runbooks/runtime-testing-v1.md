# Runtime Testing V1 Plan

Scope: get a first deployable runtime on AWS for testing, without full cutover.

## V1 Outcome

V1 is done when all of the following are true:
- The prod EC2 Docker host can run a hello-world container through the same deploy path we will use for ServiceStack.
- The host can pull images from the chosen registry.
- Route 53 can point a test hostname at the host or load balancer path.
- The runtime can connect to prod RDS.
- ETL can read from the producer-owned exports bucket using read-only access only.
- A rollback to a previous image tag has been tested once.

## Non-Goals For V1

- Full customer-facing cutover.
- CloudFront plus S3 console hosting cutover.
- Full scheduler/event infrastructure expansion.
- SES/SQS intake infrastructure.

## Phase 0: Preflight

1. Confirm the active prod stack is the one in `environments/prod`.
2. Confirm the legacy `servicestack-infrastructure` tree is reference-only.
3. Confirm the exports bucket remains producer-owned in `servicestack-exports`.
4. Confirm the runtime host can be reached through SSM.

Exit criteria:
- No ambiguity about which Terraform stack is active.
- No active Terraform resources exist for the producer-owned exports bucket.

## Phase 1: Lock The Exports Contract

1. Confirm ownership in `servicestack-exports` for:
   - exports bucket ARN
   - optional exports KMS key ARN
   - approved prefix set used by ServiceStack ETL
2. Add these values to prod environment configuration:
   - `enable_exports_read_only = true`
   - `exports_bucket_arn = "arn:aws:s3:::..."`
   - `exports_object_prefixes = ["landingdc-160426/"]` or an approved list
   - `exports_kms_key_arn = "arn:aws:kms:..."` only if SSE-KMS is used
3. Run the boundary check script before planning.
4. Run `tofu plan` and confirm the plan does not create, update, import, or destroy the producer-owned bucket.
5. Apply and verify runtime-role permissions:
   - allowed: `s3:ListBucket`, `s3:GetObject`
   - optional: `kms:Decrypt`
   - denied: write/delete/object ownership changes

Current note:
- The EC2 ETL role read-only split has been verified manually against `servicestack-exports-warehouse-prod`.
- The bucket policy deny for the EC2 role is in place, and the producer Lambda writer remains able to write.
- The remaining gap is codifying that guardrail in the owning infra repo so it survives future applies.
- DNS cutover milestone: `console.service-stack.io` now points at the new host, and `console-next.service-stack.io` remains live for transition.
- The new host currently returns the host/nginx response, so final console runtime wiring is still a follow-on step.

Exit criteria:
- ETL runtime role can read exactly what it needs and nothing more.

## Phase 2: Registry And Hello World

1. Pick the registry contract for V1.
   - Preferred: GHCR for app images.
2. Publish a tiny hello-world image tagged by commit SHA.
3. Confirm the prod host can pull that image.
4. Update the SSM deploy script or compose manifest to run that image.
5. Deploy the hello-world service through SSM.
6. Confirm logs, health check, and restart behavior.

Exit criteria:
- One immutable image tag can be built, published, pulled, and restarted on the prod host.

## Phase 3: Route 53 And TLS

1. Add the Route 53 hosted zone lookup for `service-stack.io`.
2. Add one test record first, ideally `api.service-stack.io`.
3. Attach ACM validation for `*.service-stack.io` or the exact test host.
4. Verify DNS resolves to the target runtime.
5. Verify HTTPS works end to end if the record is public-facing.

Exit criteria:
- One test hostname resolves and reaches the deployed runtime.

## Phase 4: Runtime Smoke Test

1. Deploy the first real runtime slice, ideally the API or a minimal proxy plus API.
2. Confirm the runtime can connect to RDS.
3. Confirm the runtime can start without ETL or export permission failures.
4. Run a single request through the API and verify logs.

Exit criteria:
- A deployed runtime slice starts cleanly and serves one successful request.

## Phase 5: ETL Data-Path Test

1. Execute one controlled ETL run against approved export prefixes.
2. Confirm ETL can list/read source objects and cannot write/delete.
3. Confirm inserts or updates land in the expected RDS tables.
4. Capture logs and metrics for the first run.

Exit criteria:
- A real export-to-database path has been proven once.

## Phase 6: Hardening For Ongoing Testing

1. Add a rollback exercise:
   - deploy previous image tag
   - verify API and ETL recovery
2. Document a minimum test matrix:
   - fresh deploy
   - rerun ETL
   - failure mode with bad creds or denied access
3. Keep DNS and edge changes isolated until runtime path is stable.

Exit criteria:
- The deploy and rollback loop is repeatable.

## Commands Checklist

Run from `environments/prod`:

```bash
bash ../../scripts/check-exports-boundary.sh
tofu init
tofu validate
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

Then run post-apply runtime checks from the deployment workflow and host logs.

## Notes

- The producer-owned exports bucket must remain external.
- This repo may reference and permission access, but must not create, import, mutate, or destroy that bucket.
- Keep all V1 changes in the active root layout, not the legacy `servicestack-infrastructure` snapshot.
- Keep `host_ami_id` pinned for the current working bridge so the live host stays stable while we validate the new path.
- Unpin the AMI only when we intentionally plan a host rebuild or replacement, not as part of normal incremental infra work.
