# Scripts

Place helper scripts here for validation, bootstrap support, deployment automation, or migration tasks that do not belong inside reusable OpenTofu modules.

Current examples:

- deploy-via-ssm.sh: generic rollout helper for updating a compose-based application on the production Docker host through AWS Systems Manager

Guidance:

- keep scripts environment-oriented and reusable rather than app-specific
- prefer SSM-based operational flows for the production Docker host when practical
- pair rollout scripts with verification steps such as health checks and log inspection

