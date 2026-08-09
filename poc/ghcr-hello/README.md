# GHCR Hello POC

This proof of concept validates that the production EC2 host can pull and run a private GHCR image through the SSM deployment path.

It is intentionally small:

- one static nginx-backed image published to GHCR
- one nginx edge container on the host
- one health endpoint at `/healthz`

Use this after the public `web-hello` smoke test succeeds.
