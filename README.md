# ServiceStack Infrastructure

This repository is the active home for ServiceStack infrastructure as code for the ServiceStack ecosystem.

## Purpose

This repo owns shared AWS infrastructure definitions so application repositories can stay focused on runtime behavior.

Primary scope includes:

- networking foundations
- backend hosting
- managed database infrastructure
- container registry resources
- public edge delivery and TLS termination
- scheduled and batch infrastructure
- DNS, certificates, and shared IAM
- operational recovery runbooks for protected historical data needed during migrations

## Active Repository Layout

The repo is organized around reusable modules and environment specific entrypoints.

- docs: decision records, migration notes, and runbooks
- bootstrap/state-backend: remote state bootstrap resources
- modules: reusable infrastructure building blocks
- environments/lab: lab deployment entrypoint
- environments/prod: production deployment entrypoint
- templates: cloud-init and nginx template assets
- scripts: helper scripts for validation and rollout work

## Environment Model

- Lab is the self-hosted physical home lab using Docker hosts and MinIO.
- Prod is the AWS-managed customer-facing environment.

## Local AWS Access Workflow

Use this repo workflow before any plan or apply:

1. Set your profile and region in `.env.local`.
2. Refresh your SSH allowlist CIDR to your current public IP.
3. Run AWS preflight checks to verify profile and caller identity.
4. Run plan from `environments/prod`.

Commands:

```bash
source scripts/load-local-env.sh
./scripts/update-ssh-cidr.sh
./scripts/whoami-aws.sh
tofu -chdir=environments/prod plan
```

Notes:

- Prefer SSM for host operations; treat SSH as break-glass access.
- Keep Terraform region in `environments/prod/terraform.tfvars` as the primary source; use `TF_VAR_aws_region` only for temporary overrides.
- Do not put AWS access keys in repo files. Keep credentials in local AWS profile files.
- Helper scripts are documented in `scripts/README.md`.

## Current Verified Production Baseline

The current AWS production baseline now includes:

- shared remote state backed by S3 and lock coordination
- one cost-aware VPC with a public app subnet and private database subnets
- one minimal EC2 container host managed through SSM
- one managed PostgreSQL RDS instance in private subnets
- a verified rollout and health-check path for container-based deployments

The EC2 host is intentionally lean and is prepared for Docker-based application deployment.

Current validated rollout posture:

- the consolidated app repo publishes a single GHCR-backed app image tagged by immutable commit SHA
- the app repo renders `.env.prod` from infra outputs plus SSM parameters, uploads it to the host, uploads app runtime manifests, and calls the generic SSM deploy helper from this repo
- the host runs the compose stack from `/opt/servicestack/app`
- post-deploy verification is SSM-driven and checks both container status and host-routed application endpoints
- schema init and core seed are bootstrap or DR operations, not the steady-state deploy path

See [docs/runbooks/servicestack-app-infra-contract.md](docs/runbooks/servicestack-app-infra-contract.md) for the current app/infra contract.

## Operational Recovery Notes

- Historical export data in the production warehouse bucket is treated as irreplaceable and must not be deleted, overwritten, or bulk-copied during recovery work.
- Some older menu export JSON assets under the warehouse date prefixes may be stored in S3 Glacier Flexible Retrieval while other report files remain in warmer tiers.
- Recovery for those archived objects uses temporary S3 restore requests so the original objects remain in place.
- See the runbooks folder for the documented restore workflow and verification steps.

## Working Rules

- Build new infrastructure in the active root layout, not in the legacy copy.
- Keep reusable logic in modules and environment wiring in environment stacks.
- Do not assume the lab environment should be provisioned in AWS.
- Prefer the same container runtime model in lab and prod wherever practical.
- Use Git-driven deployment automation as the default operating path.
- Keep generic deploy primitives here, but keep app-specific lifecycle wrappers in the app repo.
- Apply and validate changes in the physical lab first when practical, then promote to AWS production.
- Keep outputs stable for application repos that consume them.
- Validate plan intent against real AWS state before implementing changes.

## Legacy Snapshot

The folder named servicestack-infrastructure is a copied snapshot of the old infrastructure layout from the original app repo.

It is kept only as temporary reference material during consolidation and should not be used as the active source of truth for new infrastructure changes.

## Recommended Build Order

1. Bootstrap remote state.
2. Stand up networking and shared security primitives.
3. Add RDS and its outputs.
4. Define the deployment contract: image tags, registry choice, runtime layout, and CI deploy flow.
5. Add EC2 host and routing templates.
6. Add DNS and certificate resources.
7. Done: CloudFront and ACM front the console, API, and dashboard hostnames. The console itself is a container image on the EC2 host, so no S3 origin is used.
8. Add optional cloud-specific services only where they provide clear value without diverging from lab behavior.
