# Web Hello POC

This proof of concept validates the deployment model from this infra repo without depending on the final application consolidation.

It demonstrates:

- a portable compose-based runtime
- repo-owned nginx reverse proxy configuration
- rollout to the production Docker host through AWS Systems Manager
- public web verification through the host's HTTP endpoint

The demo intentionally uses a simple public container image so the deployment path can be proven before the real application build and registry flow are finalized.
