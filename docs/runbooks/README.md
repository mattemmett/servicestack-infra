# Runbooks

Store operational runbooks here for deploy, rollback, recovery, validation, and day two operations.

Current runbooks:

- deployment-automation.md: shared deployment contract for lab and production rollouts
- servicestack-app-infra-contract.md: current ownership and deploy contract between `servicestack-infra` and the consolidated `servicestack` app repo
- tls-cost-decision.md: SUPERSEDED. Retains the cost rationale that ruled out ALB; TLS now terminates at CloudFront
- tls-letsencrypt-ec2.md: SUPERSEDED. Never implemented; kept as the fallback design if CloudFront is removed
- ghcr-smoke-test.md: private registry pull proof on the current prod host using a tiny GHCR-backed demo image
- s3-glacier-restore.md: safe recovery workflow for historical archived exports in the production warehouse bucket
- hello-world-smoke-test.md: first deploy-and-verify check for the current EC2 host using the POC compose stack
- runtime-env-contract.md: bridge from legacy `.env.dev` variables to host runtime env files used by SSM deploy helpers
- runtime-testing-v1.md: initial AWS runtime readiness checklist for hello-world, Route 53, registry, RDS, and read-only exports access

