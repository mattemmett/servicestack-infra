# Legacy Infrastructure Reference

This directory is a copied snapshot of the old infrastructure folder from the original `servicestack` repository.

## Status

> Reference only — do not make new infrastructure changes here.

This folder is being kept temporarily so we can compare historical configuration while building out the consolidated infrastructure in this repository.

## Rules for this directory

- Do not treat this folder as the active source of truth.
- Do not add new resources, variables, or deployment changes here.
- Do use it only to reference prior Terraform, nginx, and deployment configuration.
- Validate anything reused against live AWS state and the consolidation plan before carrying it forward.

Active infrastructure work should happen in the consolidation effort for this repository, not in this legacy copy.
