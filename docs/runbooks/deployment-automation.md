# Deployment Automation Contract

This runbook defines the shared deployment model intended to keep lab and production aligned.

## Goals

- use the same application image across environments
- use the same worker and scheduler model across environments
- make deployments Git-driven and repeatable
- avoid unnecessary AWS-only branching in the runtime path

## Recommended Initial Contract

## Finalized Initial Contract (2026-08-09)

This section captures the concrete decisions required to close the initial production deploy contract.

### App image build and publish workflow

- Build and publish is owned by the application repo.
- Initial CI reference workflow is `.github/workflows/publish-ghcr-hello.yml` in this repo.
- Production host deploy trigger reference is `.github/workflows/deploy-ghcr-poc.yml` in this repo.

### Image tag strategy

- Required deploy tag: immutable commit SHA tag.
- Optional convenience tags: `latest` and release tags (for operator visibility only).
- Rollback rule: deploy by immutable tag, not by `latest`.

### Registry credential path

- Registry: GHCR (`ghcr.io`).
- CI stores registry secret as repository secret.
- Host rollout scripts accept either `GHCR_TOKEN` or `GHCR_PAT` plus `GHCR_USERNAME`.
- Local operator workflow keeps secrets in `.env.local` (untracked).

### Deploy command contract

- Deploy surface for app repos is SSM-based compose rollout using `scripts/deploy-via-ssm.sh`.
- Required inputs:
	- `INSTANCE_ID`
	- `IMAGE_TAG` (when compose uses tag indirection)
	- `GHCR_USERNAME`
	- `GHCR_TOKEN` or `GHCR_PAT`
- Default runtime paths:
	- `APP_DIR=/opt/servicestack/app`
	- `COMPOSE_FILE=docker-compose.yml`
	- `ENV_FILE=.env`

### Health-check contract

- Post-deploy verification must include:
	- `docker compose ps` shows expected services running.
	- service health endpoint returns success from host context.
- Initial required endpoint contract: `/healthz` returns HTTP 200 with body `ok`.
- Deployment is not considered successful on compose exit code alone.

### 1. Image build and tagging

Application repos should produce a single canonical container image per service.

Recommended tags:
- immutable commit tag for exact rollbacks
- optional human-friendly release tag
- optional environment tag only as a convenience alias, not the source of truth

## 2. Registry choice

Preferred initial posture:
- use a registry that both lab and prod can pull from cleanly
- keep the contract registry-agnostic
- prefer a single image source for both environments where possible

A GitHub-first registry approach is often the simplest way to keep lab and prod aligned early on.

If the image is private, the production host must receive a GHCR login before `docker compose pull`.
The shared rollout helper supports this when `GHCR_USERNAME` and `GHCR_TOKEN` are provided.
For CI-driven deployment of the GHCR proof stack, use the `Deploy GHCR POC` workflow with repository secrets for image and credentials.

## 3. Runtime layout

Both lab and prod should aim to run the same logical services:
- application service
- worker service
- scheduled or cron-driven service

Where practical, these should share:
- the same image
- the same entrypoint assumptions
- the same environment variable contract
- the same compose-level topology

## 4. Deployment flow

Recommended flow:
1. push code to Git
2. build and tag the image in CI
3. publish the image to the chosen registry
4. trigger an environment-specific rollout
5. pull and restart the target compose stack
6. verify health and log outputs

## Ownership split

- application repos own image build logic and service-specific runtime configuration
- this infra repo owns the host, network, state, and shared deployment conventions
- helper rollout scripts can live here when they are generic and environment-oriented rather than app-specific

## Current Verified Production Posture

The current production deployment path has been verified around a small SSM-managed EC2 Docker host.

Operational expectations:
- deployments should be remotely executable through Systems Manager rather than requiring ad hoc SSH-only steps
- compose-based application rollouts should include explicit health verification after restart
- deployment success should be confirmed with both service health checks and runtime logs, not just command exit status

