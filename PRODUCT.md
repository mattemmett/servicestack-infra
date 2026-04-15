# PRODUCT.md

Scope: repository product intent, operator outcomes, and business-facing infrastructure goals
See also: ARCHITECTURE.md for technical structure, AGENTS.md for repo workflow and operating rules

---

## Product Overview

ServiceStack Infrastructure is the shared infrastructure control plane for the ServiceStack ecosystem.

Its purpose is to make AWS infrastructure repeatable, auditable, environment-aware, and cost-conscious while keeping application repositories focused on runtime behavior.

## Core Value

- Centralize infrastructure ownership in one place
- Reduce manual AWS configuration drift
- Keep lab and production environments understandable and reproducible
- Enable safe rollout and rollback for infrastructure changes
- Support early-stage cost discipline while the platform is still being built out

## In Scope

This repo is intended to own infrastructure for:

- networking foundations
- backend hosting for the API and related workloads
- managed database infrastructure
- container registry resources
- static frontend hosting and edge delivery
- scheduled ETL runtime infrastructure
- DNS, certificates, and shared IAM
- later invoice-intake infrastructure such as SES and SQS

## Out Of Scope

This repo does not own:

- FastAPI application logic
- ETL business logic
- dashboard feature behavior
- invoice intelligence business workflows
- mobile or Flutter application code

## Current Phase Priorities

Near-term priorities are:

1. keep the new production baseline stable and well-documented
2. establish Git-driven deployment automation for both lab and prod
3. keep the container runtime and worker model aligned across environments
4. prepare safe historical data recovery needed to support the RDS migration path
5. continue replacing manual or repo-local infra drift with repeatable IaC

## Current Verified Baseline

The repo now has a verified low-cost production baseline consisting of:

- team-safe remote state
- a production VPC and security groups
- a minimal EC2 Docker host managed through SSM
- a managed PostgreSQL RDS instance
- a documented recovery path for archived historical exports needed during migration work

This establishes the core hosting path needed for the next deployment steps without overbuilding the platform too early.

## Operator Goals

The infrastructure should let operators:

- understand what exists in AWS and in the self-hosted lab and why
- validate changes in the physical lab first, then promote to AWS production
- recover safely from mistakes or failed rollouts
- keep secrets out of source control
- avoid unnecessary recurring cost during the early stage of the platform

## Cost And Safety Constraints

At this stage the default posture is:

- prefer the simplest viable AWS topology
- avoid always-on managed components that add cost without clear immediate value
- treat destructive changes as explicit and reviewed
- favor reversible changes and clear outputs for dependent repos

Examples of this posture include delaying higher-cost networking choices until they are justified by concrete runtime needs.

## Success Signals

This repo is succeeding when:

- OpenTofu plans are clear and reproducible
- environment state is isolated and team-safe
- application repos can consume stable infra outputs
- core platform services can be deployed without manual console drift
- monthly baseline AWS cost stays appropriately lean for the current phase

---

File: PRODUCT.md
Audience: agents and maintainers who need the repo purpose, scope, and operating priorities
