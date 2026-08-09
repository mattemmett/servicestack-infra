# Compose Templates

These templates are intended to support the same logical runtime shape in both the self-hosted lab and AWS production.

Goal:
- one application image contract
- one worker model
- one scheduled-job model
- environment-specific values supplied through env files or CI variables rather than architecture drift

Included templates:
- `docker-compose.portable.yml.example`: portable runtime shape for app, worker, scheduler
- `.env.servicestack.runtime.example`: runtime env contract bridge from legacy `.env.dev` style keys
