# 0001: Environment Model Is Self-Hosted Lab Plus AWS Production

## Status
Accepted

## Context

During early consolidation work, an AWS-based lab assumption was introduced into the repo scaffolding.
That assumption does not match the actual deployment topology.

The real environment model is:

- Dev: local or containerized development workflows
- Lab: physical home lab using Docker hosts and MinIO
- Prod: AWS-managed production environment

## Decision

This repo should treat AWS as the primary production infrastructure target.

The lab environment should not be assumed to be provisioned through AWS from this repository unless a future explicit decision changes that model.

## Consequences

- Architecture and operating docs must describe lab as self-hosted.
- Cost-sensitive AWS design should focus on production needs.
- Lab validation should happen on the physical lab stack where practical.
- AWS lab provisioning should remain opt-in, not an implicit baseline.
