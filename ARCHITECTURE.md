# ARCHITECTURE.md

Scope: technical architecture, repository structure, environment topology, and infrastructure design patterns
See also: PRODUCT.md for repo intent and priorities, AGENTS.md for workflow rules

---

## Technical Stack

| Layer | Technology | Purpose |
|---|---|---|
| IaC | OpenTofu | Infrastructure provisioning and change management for AWS-managed pieces |
| Production Cloud | AWS | Production platform for compute, storage, networking, DNS, and managed services |
| Lab Runtime | Docker hosts plus MinIO | Self-hosted integration environment in the physical home lab |
| State | S3 plus lock coordination | Team-safe remote state management for AWS-managed infrastructure |
| Runtime Targets | EC2, RDS, S3, CloudFront, EventBridge, ECS or Fargate | Primary AWS production targets as consolidation progresses |

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

## Environment Model

The repo currently supports a mixed environment model:

- Dev: local or containerized developer workflows
- Lab: self-hosted physical lab environment using Docker hosts and MinIO
- Prod: AWS-managed production environment

Important constraint:
- Do not assume the lab environment should be provisioned in AWS.
- AWS infrastructure work in this repo is primarily targeted at production unless a specific AWS lab task is explicitly requested.

## Composition Pattern

The intended composition flow is:

1. bootstrap shared remote state for AWS-managed infrastructure
2. build reusable modules for production AWS concerns
3. validate application and deployment behavior in the self-hosted lab where practical
4. promote stable infrastructure changes into AWS production

This keeps environment wiring separate from reusable infrastructure logic while matching the actual deployment topology.

## Target Platform Topology

The current target topology is:

- self-hosted lab environment in the physical home lab using Docker hosts and MinIO for pre-production validation
- one AWS VPC with a public application subnet and private database subnets
- one AWS EC2 Docker host for the production backend and reverse proxy path
- one AWS RDS Postgres instance replacing local EC2-hosted Postgres in production
- AWS S3 and CloudFront for the Flutter web console in production
- AWS EventBridge and ECS or Fargate for nightly ETL scheduling and execution in production
- AWS Route 53 and ACM for service-stack.io routing and certificates
- shared IAM roles and policies for deploy and runtime use
- later SES and SQS support for the invoice intake path

Implementation note:
- the production EC2 host is intentionally minimal and is managed through SSM
- on Amazon Linux 2023, Docker is installed from the native distro packages
- Docker Compose is installed via the official Docker CLI plugin path because a native Compose package is not consistently available in this environment

## Network Posture

The repo should start with a cost-aware baseline.

Current design preference:
- use an Internet Gateway for public edge access where needed
- place application-facing infrastructure in public networking only where required
- place database infrastructure in private subnets across multiple availability zones
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
