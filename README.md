# ServiceStack Infrastructure

This repository is the active home for ServiceStack infrastructure as code during the consolidation effort.

## Current Status

- The long-term active layout is now scaffolded at the repo root.
- The copied legacy infrastructure snapshot is preserved only for reference.
- New infrastructure work should be built in the environment and module structure in this repository.

## Repo Layout

- docs: decisions, migration notes, and runbooks
- bootstrap/state-backend: remote state bootstrap resources
- modules: reusable infrastructure building blocks
- environments: lab and prod deployment entrypoints
- templates: cloud-init and nginx template assets
- scripts: helper scripts for operations and rollout work

## Legacy Snapshot

The folder named servicestack-infrastructure is the old copied layout from the original app repo.
It should not be used as the active source of truth for new infrastructure changes.
