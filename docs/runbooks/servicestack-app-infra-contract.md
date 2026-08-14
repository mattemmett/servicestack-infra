# ServiceStack App / Infra Contract

Purpose: define the current operational and ownership contract between `servicestack-infra` and the consolidated `servicestack` app repo.

This document is the current source of truth for:

- who owns which part of production rollout
- which values cross the repo boundary
- which production flows are bootstrap-only versus steady-state-safe
- what remains unfinished in the migration from bootstrap-style initialization to release-safe migrations

## Current Model

The application runtime is deployed from `servicestack`.

The production host, network, database infrastructure, Terraform outputs, and generic SSM helper scripts are owned by `servicestack-infra`.

### Public edge (added 2026-08-13)

All public traffic terminates TLS at CloudFront and is forwarded to the EC2 host over port 80, which is reachable only from CloudFront's origin-facing prefix list.

| Hostname | Distribution | Caching | Backing service |
|---|---|---|---|
| `console.service-stack.io`, `console-next` | `cloudfront_site` | cached, `/api/*` and `/auth/*` uncached | `console` container, `/api/` and `/auth/` proxied to `api` |
| `api.service-stack.io`, `api-next` | `cloudfront_app` | disabled | `api` container |
| `dashboard.service-stack.io`, `dashboard-next` | `cloudfront_app` | disabled | `dashboard` container |

Notes that matter when changing this:

- The `Managed-AllViewer` origin request policy is required. Without it CloudFront strips `Authorization` and every authenticated call fails.
- `cloudfront_app` must keep caching disabled by default, because those hostnames serve dynamic responses at the root rather than under `/api/*`.
- The `-next` hostnames exist to validate the edge before cutting a live hostname over.
- Streamlit WebSockets work through CloudFront. Verify with HTTP/1.1; an HTTP/2 request cannot carry an `Upgrade` header and will look like a failure.

The current validated production path is:

1. `servicestack` renders `.env.prod` from SSM secrets plus Terraform outputs published by `servicestack-infra`
2. `servicestack` builds and publishes the app image to GHCR using an immutable commit SHA tag
3. `servicestack` builds and publishes the separate Flutter console image when `CONSOLE_IMAGE` changes
4. `servicestack` uploads `.env.prod`, `docker-compose.yml`, and app `nginx.conf` to `/opt/servicestack/app` on the infra-managed host
5. `servicestack` appends `GHCR_IMAGE`, `CONSOLE_IMAGE`, and `ENV_FILE` to the uploaded runtime env payload
6. `servicestack` calls `servicestack-infra/scripts/deploy-via-ssm.sh` to perform the generic host-side compose rollout
7. `servicestack` refreshes the separately versioned `console` service and force-recreates nginx so uploaded routing config is applied
8. `servicestack` runs post-deploy smoke checks through public CloudFront-backed hostnames

## Ownership Split

### `servicestack-infra` owns

- Terraform state, environments, and modules
- EC2 host provisioning and SSM access model
- RDS provisioning and published outputs
- Route 53, certificates, security groups, and host exposure
- CloudFront distributions and the ACM wildcard certificate that terminate public TLS
- generic helper scripts such as `push-env-to-host.sh` and `deploy-via-ssm.sh`
- app-facing output stability and runtime contract documentation

### `servicestack` owns

- Dockerfile and application container image contents
- the console image (`ghcr.io/mattemmett/servicestack-console`), built from the host Flutter toolchain
- app `docker-compose.yml`, including the `console` service
- app runtime `nginx.conf`, including console routing and the same-origin `/api/` and `/auth/` proxies
- `.env.prod` rendering logic from outputs plus SSM secrets
- bootstrap, deploy, smoke, and seed command surfaces
- schema init, core seed, and future incremental schema migration runner

## Current Command Surface

### In `servicestack`

- `make prod-bootstrap`
- `make prod-deploy`
- `make prod-smoke`
- `make publish-console-ghcr`
- `make db-init-ssm`
- `make etl-seed-core-ssm`
- `make prod-migrate` (placeholder until incremental migrations are implemented)

### In `servicestack-infra`

- `scripts/push-env-to-host.sh`
- `scripts/deploy-via-ssm.sh`

These infra scripts are generic primitives. They are not the full application lifecycle.

## Shared Values

### Terraform outputs published by infra

- `host_instance_id`
- `host_public_ip`
- `host_public_dns`
- `rds_endpoint`
- `rds_port`
- Route 53 record FQDN outputs used during rollout

### SSM values consumed by app deploy logic

- `/servicestack/db-user`
- `/servicestack/db-password`
- `/servicestack/jwt-secret`
- `/servicestack/s3-exports-bucket`
- `/servicestack/s3-location-prefix`

### Runtime file contract on host

Target directory:

- `/opt/servicestack/app`

Current uploaded files:

- `.env.prod`
- `docker-compose.yml`
- `nginx.conf`

Important detail:

- the uploaded `.env.prod` payload currently includes `GHCR_IMAGE`, `CONSOLE_IMAGE`, and `ENV_FILE=.env.prod` so compose interpolation resolves the correct runtime env file and image tags on host

## Bootstrap vs Steady-State

### Bootstrap or DR only

Use these when bringing up a new environment or rebuilding from scratch:

- schema init
- core identity/auth seed
- bounded ETL backfill or initial imports

The current schema init path is destructive and drops/recreates schema objects. It must not be treated as a release-safe migration step.

### Steady-state releases

Normal application releases should be:

1. publish image
2. deploy updated compose stack
3. refresh the console image when `CONSOLE_IMAGE` changes
4. force-recreate nginx when routing config changes
5. run smoke checks

That is the role of `make prod-deploy` in the app repo.

## Health Contract

Current validated smoke checks:

- API route: `Host: api.service-stack.io`, path `/health`, returns HTTP 200 and JSON status payload
- Dashboard route: `Host: dashboard.service-stack.io`, path `/`, returns HTTP 200
- `docker compose ps` shows the expected services up on the host

## Migration Gap

The major remaining gap between bootstrap-era operations and mature release operations is incremental production schema migration.

Desired future state:

- `servicestack` owns a real incremental migration runner such as Alembic
- `make prod-migrate` becomes the app repo entrypoint for schema changes
- this repo documents the contract inputs and rollback expectations, but does not own app schema behavior

Until that exists:

- do not document `db-init-ssm` as migration
- do not add infra automation that assumes schema bootstrap is safe for steady-state releases

## Change Rules

When this contract changes:

1. update this document first
2. update `INFRA_HANDOFF.md` if the change affects session startup context
3. update `AGENTS.md` if the change affects repo ownership or agent routing
4. update `servicestack` docs and command surface in the same rollout
