# 0002 - Portable Container Runtime Model

Status: accepted
Date: 2026-04-15

## Context

The consolidation effort initially leaned too heavily toward AWS-native runtime services.

That creates a meaningful risk:
- the self-hosted lab already runs Docker-based workloads and scheduled container jobs
- production would drift into a different runtime model if scheduled jobs moved into AWS-native services too early
- deployment automation becomes harder when lab and prod do not share the same image, worker, and scheduling behavior

The goal of this repo is not only to centralize infrastructure, but to restore a single operational model across environments wherever practical.

## Decision

We will prefer a portable, container-first operating model:

- use the same application containers in lab and prod
- use the same worker and cron model in lab and prod wherever practical
- prioritize Git-driven deployment automation
- treat AWS primarily as hosting, networking, and managed data infrastructure
- only introduce AWS-native runtime services when they add clear value without creating avoidable behavior drift

## Implications

This means:

- AWS EventBridge, ECS, or Fargate are not the default assumption for scheduled work
- the deployment contract becomes a first-class repo concern
- registry choice should remain portable across lab and production
- the current EC2 Docker host and RDS baseline remain valid and useful

## Follow-on Work

Immediate follow-on work should focus on:

1. image naming and tagging conventions
2. registry strategy for both lab and prod
3. a standard compose-based runtime layout
4. GitHub-driven deployment automation for both environments
