# AGENTS.md

Scope: Repository-level operating guide for agents working in servicestack-infra.

---

## Purpose

This repository owns infrastructure as code for the ServiceStack ecosystem.

Primary goals:
- Centralize AWS infrastructure definitions in one place.
- Keep application repos focused on runtime code.
- Make infra changes auditable, reversible, and environment-aware.

Planning note:
- The consolidation plan is the starting intent, not ground truth.
- Validate assumptions against actual cloud state and existing repo code before applying changes.

---

## Ownership

servicestack-infra should own infrastructure definitions for:
- Networking foundations such as VPCs, subnets, routing, and security groups
- Compute hosting for backend workloads such as EC2 and ECS or Fargate
- Database infrastructure such as RDS Postgres
- Container registry resources such as ECR
- Object storage and edge delivery for frontend hosting such as S3 and CloudFront
- Scheduling and batch orchestration primitives such as EventBridge and ECS task scheduling
- DNS and certificates such as Route 53 and ACM
- Shared IAM roles and policies used by deploy pipelines and runtime services
- Infrastructure for the IIP intake path when folded in later, including SES, SQS, and supporting IAM

Repos that still own application behavior:
- servicestack: API, ETL logic, dashboard, schema behavior
- servicestack-exports: Toast SFTP acquisition runtime and its app-layer logic
- servicestack-iip: invoice intelligence runtime until fold-in is complete
- servicestack-platform: ecosystem narrative and docs

Rule:
- Infra definitions live here.
- Business logic and app runtime code do not.

---

## Repository Layout Conventions

Use the active repo root structure as the working source of truth.

Expected layout:
- bootstrap/state-backend: one-time remote state bootstrap resources
- modules: reusable infrastructure building blocks with narrow responsibilities
- environments/lab: lab deployment entrypoint
- environments/prod: production deployment entrypoint
- templates: rendered assets such as cloud-init and nginx configuration
- docs: architecture decisions, runbooks, and migration notes
- scripts: helper tooling for validation, rollout, and migration support

Legacy layout rule:
- The folder named servicestack-infrastructure is reference-only during consolidation.
- Do not treat it as the active location for new infrastructure development.
- Reuse from it only after validating against the plan and live AWS state.

---

## Source Of Truth And Validation

For each infra task, run this order:
1. Read target state from CONSOLIDATION_PLAN.md at workspace root.
2. Compare with current repo code and live environment facts.
3. Record any mismatch in the appropriate docs or decision note.
4. Implement only after the mismatch is understood and approved.

Do not assume:
- Resource names
- Existing VPC layout
- Active deployment topology
- Current secrets strategy
- Existing IAM trust relationships

Always verify first.

---

## Environments

Expected environment tiers:
- Dev: local or containerized developer workflows
- Lab: pre-production integration environment
- Prod: customer-facing environment

Environment rules:
- Keep variable values environment-scoped.
- Keep state isolation clear between environments.
- Never hardcode prod-only identifiers into shared modules.
- Apply in lab first whenever practical.

---

## State And Safety

State management:
- Use remote state backend for team-safe operations.
- Lock state during apply operations.
- Keep backend bootstrap steps documented and separate from workload modules.

Safety controls:
- Treat destructive actions as explicit opt-in.
- Prefer deletion protection for critical data services.
- Use snapshot and rollback plans before risky migrations.
- Keep drift detection in normal workflow.

Secrets:
- No secrets in source control.
- Use managed secret stores and runtime injection.

---

## Change Workflow

Default workflow for any change:
1. Confirm owner: does this belong in infra or an app repo?
2. Capture assumptions and unknowns.
3. Resolve unknowns by reading current code and environment configuration.
4. Plan the smallest viable infrastructure change.
5. Apply in lab first.
6. Validate outputs consumed by app repos.
7. Promote to prod with rollback readiness.

For cross-repo changes:
1. Update producer contract first.
2. Update consumer configuration second.
3. Enable automation after observability and fallback are in place.

---

## Required Outputs And Contracts

Keep infra outputs stable and documented for consumers.

Typical required outputs:
- database connection endpoint metadata
- network and security identifiers used by runtime stacks
- registry coordinates for container image publishing
- host and distribution coordinates for API and frontend routing

Contract rule:
- If output shape or semantics change, update consumer repos in the same rollout plan.

---

## Deployment And CI Expectations

Deployment posture:
- Infra changes are reviewed and applied through reproducible IaC workflows.
- Prefer non-interactive CI execution for plan and apply where feasible.

CI baseline expectations:
- format and validation checks
- plan artifact generation
- approval gates for production apply
- clear mapping from commit to applied change set

---

## Migration Priorities From Consolidation Plan

Priority sequence to align with current consolidation intent:
1. Establish the infra repository baseline and remote state pattern.
2. Consolidate existing infrastructure definitions from app repos.
3. Stand up or validate the RDS target and migration path.
4. Ensure the ECR path for backend image delivery.
5. Define the frontend hosting edge path using S3 and CloudFront.
6. Define ETL scheduler and runtime infrastructure.
7. Incorporate DNS and certificate management for service-stack.io domains.
8. Fold in IIP intake infrastructure when the application fold-in reaches that phase.

Each priority requires plan-versus-reality validation before execution.

---

## Agent Operating Rules

When working in this repo:
- Prefer the smallest safe change.
- Avoid broad refactors without a concrete migration reason.
- Keep module boundaries clear and composable.
- Document rationale for non-obvious infrastructure decisions.
- Do not delete legacy resources until replacement is verified.
- Favor the active module plus environment layout for all new work.

If unsure:
- Pause and document unknowns.
- Ask for explicit decision before high-risk or irreversible actions.

---

## Coordination Notes

This repo is part of a multi-repo workspace. For cross-repo tasks:
- Keep the workspace-level AGENTS.md context in view.
- Track sequencing constraints in the workspace consolidation tracker.
- Record durable architecture decisions where future agents can find them quickly.

