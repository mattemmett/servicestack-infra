# TLS Cost Decision

> **SUPERSEDED 2026-08-13.** TLS is now terminated at CloudFront using an ACM wildcard
> certificate for `*.service-stack.io`. Let's Encrypt on-host was rejected because certbot
> state lives on the instance root volume (`delete_on_termination = true`), so any host
> replacement would re-issue certificates and burn Let's Encrypt rate limits. CloudFront's
> free tier made managed, auto-renewing certificates cost-neutral at current volume.
> Kept for the cost rationale, which still explains why ALB was not chosen.

## Decision

For the current stage, keep a low-cost TLS posture:

- terminate TLS on the existing EC2 host nginx runtime
- use Let's Encrypt certificates on-host
- keep Route 53 records pointing to the EC2 host
- do not introduce ALB yet

This keeps fixed AWS spend low while preserving a production-grade HTTPS baseline.

## Why this is the default now

- ALB introduces recurring fixed cost before traffic or revenue justifies it
- ACM certificates are free, but ACM-only API TLS typically implies ALB or CloudFront fronting
- current scale is small and operational simplicity plus low burn is the priority

## Guardrails

- SSM remains the primary host access path
- SSH stays restricted to trusted /32 CIDRs as break-glass only
- health checks must continue to gate deployment success
- DNS ownership and certificate handling stay in infra docs and runbooks

## Upgrade triggers for ALB plus ACM

Move from EC2 nginx TLS to ALB plus ACM when any of these become true:

1. multi-instance service rollout is required
2. zero-downtime rolling deploys are required
3. WAF, managed edge policy, or advanced listener routing is required
4. external uptime expectations or traffic patterns justify the added fixed cost

## Implementation order for current decision

1. keep current host-level HTTPS routing as the baseline
2. document cert issuance and renewal operations in [tls-letsencrypt-ec2.md](./tls-letsencrypt-ec2.md)
3. validate HTTPS endpoint behavior alongside existing /healthz checks
4. track cert expiry visibility in ops checks

## Cost stance

- prefer variable spend over fixed platform spend until customer and traffic growth is proven
- optimize for survivability and iteration speed in early SaaS phase
- re-evaluate quarterly or at each major customer onboarding milestone
