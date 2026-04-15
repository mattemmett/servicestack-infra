# Deployment Automation Contract

This runbook defines the shared deployment model intended to keep lab and production aligned.

## Goals

- use the same application image across environments
- use the same worker and scheduler model across environments
- make deployments Git-driven and repeatable
- avoid unnecessary AWS-only branching in the runtime path

## Recommended Initial Contract

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

