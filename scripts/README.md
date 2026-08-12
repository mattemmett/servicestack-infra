# Scripts

Place helper scripts here for validation, bootstrap support, deployment automation, or migration tasks that do not belong inside reusable OpenTofu modules.

Current examples:

- deploy-via-ssm.sh: generic rollout helper for updating a compose-based application on the production Docker host through AWS Systems Manager
- check-exports-boundary.sh: static guardrail that fails if active Terraform starts to manage or hardcode the producer-owned exports warehouse bucket
- push-env-to-host.sh: uploads a local runtime env file to the production host through AWS Systems Manager
- load-local-env.sh: sources local-only environment settings from .env.local for repeatable local workflows
- whoami-aws.sh: preflight check that verifies AWS profile and region selection, then prints STS caller identity before plan/apply
- update-ssh-cidr.sh: refreshes TF_VAR_ssh_cidr_blocks in .env.local to your current public IP /32

Guidance:

- keep scripts environment-oriented and reusable rather than app-specific
- current production app wrappers live in the `servicestack` repo and call these scripts; do not duplicate app lifecycle orchestration here unless it is truly infra-generic
- prefer SSM-based operational flows for the production Docker host when practical
- pair rollout scripts with verification steps such as health checks and log inspection
- run exports-boundary checks before plan/apply when changes touch Terraform ownership patterns

