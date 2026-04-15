# ARCHITECTURE.md

Scope: technical architecture, repository structure, environment topology, and infrastructure design patterns
See also: PRODUCT.md for repo intent and priorities, AGENTS.md for workflow rules

---

## Technical Stack

| Layer | Technology | Purpose |
|---|---|---|
| IaC | OpenTofu | Infrastructure provisioning and change management |
| Cloud | AWS | Runtime platform for compute, storage, networking, DNS, and managed services |
| State | S3 plus lock coordination | Team-safe remote state management |
| Runtime Targets | EC2, RDS, S3, CloudFront, EventBridge, ECS or Fargate | Target platform services as consolidation progresses |

## Repository Structure

The active repository is organized around a small number of top-level concerns:

- bootstrap/state-backend: one-time shared state backend resources
- modules: reusable, narrow-responsibility infrastructure building blocks
- environments/lab: lab composition entrypoint
- environments/prod: production composition entrypoint
- templates: rendered assets such as cloud-init and nginx configuration
- docs: runbooks, decisions, and migration notes
- scripts: helper operations and validation support

The folder named servicestack-infrastructure is legacy reference only and is not the active source of truth for new work.

## Composition Pattern

The intended composition flow is:

1. bootstrap shared remote state
2. compose reusable modules in the lab environment
3. validate outputs and behavior
4. promote the same module patterns into production

This keeps environment wiring separate from reusable infrastructure logic.

## Target Platform Topology

The consolidation plan points toward this target topology:

- one EC2 Docker host for the backend and reverse proxy path
- one RDS Postgres instance replacing local EC2-hosted Postgres
- S3 and CloudFront for the Flutter web console
- EventBridge and ECS or Fargate for nightly ETL scheduling and execution
- Route 53 and ACM for service-stack.io routing and certificates
- shared IAM roles and policies for deploy and runtime use
- later SES and SQS support for the invoice intake path

## Network Posture

The repo should start with a cost-aware baseline.

Current design preference:
- use an Internet Gateway for public edge access where needed
- avoid adding a NAT Gateway until there is a concrete operational need that justifies the recurring cost
- keep security groups explicit and least-privilege oriented
- isolate environment values cleanly between lab and production

## State Management Pattern

Remote state is expected to use:

- a shared S3 bucket for OpenTofu state
- locking coordination for safe team operations
- separate state keys for each environment

Bootstrap resources are intentionally separated from workload stacks so the backend can be created once and reused safely.

## Module Boundary Guidance

Each module should:

- own one narrow concern
- accept environment-scoped inputs
- expose stable outputs
- avoid hardcoded production identifiers
- be composable from environment entrypoints

Likely early modules include networking, security, IAM, RDS Postgres, EC2 host, ECR, DNS, and certificates.

## Change And Promotion Model

The preferred sequence for infrastructure work is:

1. validate the target against the consolidation plan and current AWS reality
2. implement the smallest viable module or change
3. plan and verify in lab first
4. promote to prod with rollback readiness

## Durable Constraints

- no secrets in source control
- no direct dependence on the legacy flat layout for new work
- avoid broad refactors without a migration reason
- preserve stable outputs for consumer repos
- document non-obvious infra decisions in the repo docs layer

---

File: ARCHITECTURE.md
Audience: agents and maintainers who need technical structure and implementation guidance for the infra repo
