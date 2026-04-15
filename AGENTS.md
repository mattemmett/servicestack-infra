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
- Networking foundations (VPC, subnets, routing, security groups)
- Compute hosting for backend workloads (EC2 and/or ECS/Fargate as adopted)
- Database infrastructure (RDS Postgres)
- Container registry resources (ECR)
- Object storage and edge delivery for frontend hosting (S3 and CloudFront)
- Scheduling and batch orchestration primitives (EventBridge, ECS task scheduling)
- DNS and certificates (Route53, ACM)
- Shared IAM roles and policies used by deploy pipelines and runtime services
- Infrastructure for IIP intake path when folded in (SES, SQS, supporting IAM)

Repos that still own application behavior:
- servicestack: API, ETL logic, dashboard, schema behavior
- servicestack-exports: Toast SFTP acquisition runtime and its app-layer logic
- servicestack-iip: invoice intelligence runtime until fold-in is complete
- servicestack-platform: ecosystem narrative and docs

Rule:
- Infra definitions live here.
- Business logic and app runtime code do not.

---

## Source Of Truth And Validation

For each infra task, run this order:
1. Read target state from CONSOLIDATION_PLAN.md at workspace root.
2. Compare with current repo code and live environment facts.
3. Record any mismatch in the workspace tracker decision log.
4. Implement only after mismatch is understood and approved.

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
- Lab: pre-prod integration environment
- Prod: customer-facing environment

Environment rules:
- Keep variable values environment-scoped.
- Keep state isolation clear between environments.
- Never hardcode prod-only identifiers into shared modules.

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
1. Confirm owner: does this belong in infra or app repo?
2. Capture assumptions and unknowns.
3. Resolve unknowns by reading current code and environment config.
4. Plan minimal viable infra change.
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
- Database connection endpoint metadata
- Network and security identifiers used by runtime stacks
- Registry coordinates for container image publishing
- Host and distribution coordinates for API and frontend routing

Contract rule:
- If output shape or semantics change, update consumer repos in the same rollout plan.

---

## Deployment And CI Expectations

Deployment posture:
- Infra changes are reviewed and applied through reproducible IaC workflows.
- Prefer non-interactive CI execution for plan and apply where feasible.

CI baseline expectations:
- Format and validation checks
- Plan artifact generation
- Approval gates for production apply
- Clear mapping from commit to applied change set

---

## Migration Priorities From Consolidation Plan

Priority sequence to align with current consolidation intent:
1. Establish infra repository baseline and remote state pattern.
2. Consolidate existing infrastructure definitions from app repos.
3. Stand up or validate RDS target and migration path.
4. Ensure ECR path for backend image delivery.
5. Define frontend hosting edge path (S3 and CloudFront).
6. Define ETL scheduler and runtime infrastructure.
7. Incorporate DNS and certificate management for service-stack.io domains.
8. Fold in IIP intake infrastructure when application fold-in reaches that phase.

Each priority requires plan-versus-reality validation before execution.

---

## Agent Operating Rules

When working in this repo:
- Prefer smallest safe change.
- Avoid broad refactors without a concrete migration reason.
- Keep module boundaries clear and composable.
- Document rationale for non-obvious infrastructure decisions.
- Do not delete legacy resources until replacement is verified.

If unsure:
- Pause and document unknowns.
- Ask for explicit decision before high-risk or irreversible actions.

---

## Coordination Notes

This repo is part of a multi-repo workspace. For cross-repo tasks:
- Keep the workspace-level AGENTS.md context in view.
- Track sequencing constraints in the workspace consolidation tracker.
- Record durable architecture decisions where future agents can find them quickly.
