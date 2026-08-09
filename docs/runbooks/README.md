# Runbooks

Store operational runbooks here for deploy, rollback, recovery, validation, and day two operations.

Current runbooks:

- deployment-automation.md: shared deployment contract for lab and production rollouts
- tls-cost-decision.md: cost-first TLS decision and upgrade triggers for when to move from host nginx TLS to ALB plus ACM
- tls-letsencrypt-ec2.md: SSM-first runbook for issuing and renewing Let's Encrypt certificates on the current EC2 host model
- ghcr-smoke-test.md: private registry pull proof on the current prod host using a tiny GHCR-backed demo image
- s3-glacier-restore.md: safe recovery workflow for historical archived exports in the production warehouse bucket
- hello-world-smoke-test.md: first deploy-and-verify check for the current EC2 host using the POC compose stack
- runtime-env-contract.md: bridge from legacy `.env.dev` variables to host runtime env files used by SSM deploy helpers
- runtime-testing-v1.md: initial AWS runtime readiness checklist for hello-world, Route 53, registry, RDS, and read-only exports access

