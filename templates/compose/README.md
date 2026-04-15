# Compose Templates

These templates are intended to support the same logical runtime shape in both the self-hosted lab and AWS production.

Goal:
- one application image contract
- one worker model
- one scheduled-job model
- environment-specific values supplied through env files or CI variables rather than architecture drift
