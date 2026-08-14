# TLS on EC2 with Let's Encrypt (Cost-First)

> **SUPERSEDED 2026-08-13.** Not implemented. TLS is terminated at CloudFront with an ACM
> wildcard certificate; see `docs/runbooks/servicestack-app-infra-contract.md`. This runbook
> is retained only as the fallback design if CloudFront is ever removed.

Purpose: run HTTPS for the current single-host production model without introducing ALB fixed cost.

This runbook uses:

- Route 53 records pointing directly to the prod EC2 host
- certbot on the host
- nginx in the compose runtime as TLS terminator
- AWS SSM for remote execution (no SSH required)

## Scope

Applies to current hostnames served from the EC2 host, for example:

- api.service-stack.io
- dashboard.service-stack.io

## Preconditions

1. DNS A records already point to the EC2 public IP.
2. Security group allows inbound 80 and 443.
3. You can run SSM commands against the prod host.
4. Compose runtime includes nginx and can mount host cert paths.

## 1. Verify DNS Resolution

From your local machine:

```bash
dig +short api.service-stack.io
dig +short dashboard.service-stack.io
```

Expected: both resolve to the current prod host public IP.

## 2. Install certbot on the Host

Run via SSM:

```bash
AWS_PAGER="" aws ssm send-command \
  --no-cli-pager \
  --region us-east-1 \
  --instance-ids i-0eec1257722b6b1c9 \
  --document-name AWS-RunShellScript \
  --comment "Install certbot" \
  --parameters 'commands=[
    "set -euo pipefail",
    "sudo dnf install -y certbot",
    "certbot --version"
  ]'
```

## 3. Issue Certificates (Standalone Mode)

This uses certbot standalone on port 80, so stop nginx briefly during issuance.

```bash
AWS_PAGER="" aws ssm send-command \
  --no-cli-pager \
  --region us-east-1 \
  --instance-ids i-0eec1257722b6b1c9 \
  --document-name AWS-RunShellScript \
  --comment "Issue letsencrypt certs" \
  --parameters 'commands=[
    "set -euo pipefail",
    "cd /opt/servicestack/poc-ghcr-hello || true",
    "docker compose down || true",
    "sudo certbot certonly --standalone --non-interactive --agree-tos --email ops@service-stack.io -d api.service-stack.io -d dashboard.service-stack.io",
    "docker compose up -d || true",
    "sudo certbot certificates"
  ]'
```

Notes:

- Replace email/domain values with your operator mailbox and real hostnames.
- For production app stacks, use the target compose directory instead of `poc-ghcr-hello`.

## 4. Wire nginx to Certificate Paths

In your nginx runtime config, reference host cert paths:

- `/etc/letsencrypt/live/api.service-stack.io/fullchain.pem`
- `/etc/letsencrypt/live/api.service-stack.io/privkey.pem`

If nginx is containerized, mount host certs read-only into the container:

```yaml
volumes:
  - /etc/letsencrypt:/etc/letsencrypt:ro
```

## 5. Configure Renewal

Create a host cron job for daily renewal checks:

```bash
AWS_PAGER="" aws ssm send-command \
  --no-cli-pager \
  --region us-east-1 \
  --instance-ids i-0eec1257722b6b1c9 \
  --document-name AWS-RunShellScript \
  --comment "Configure certbot renewal" \
  --parameters 'commands=[
    "set -euo pipefail",
    "echo \"17 3 * * * root certbot renew --quiet --deploy-hook \\\"docker compose -f /opt/servicestack/poc-ghcr-hello/docker-compose.yml up -d\\\"\" | sudo tee /etc/cron.d/certbot-renew >/dev/null",
    "sudo chmod 644 /etc/cron.d/certbot-renew",
    "sudo cat /etc/cron.d/certbot-renew"
  ]'
```

Adjust compose path to the real runtime stack before enabling.

## 6. Validate HTTPS

From local machine:

```bash
curl -I https://api.service-stack.io/healthz
curl -I https://dashboard.service-stack.io/healthz
```

Expected:

- HTTP status 200 or expected app health status
- valid certificate chain

Optional certificate details:

```bash
echo | openssl s_client -connect api.service-stack.io:443 -servername api.service-stack.io 2>/dev/null | openssl x509 -noout -issuer -subject -dates
```

## 7. Rollback

If HTTPS rollout fails:

1. Restore last known working nginx config.
2. Re-deploy previous compose stack.
3. Keep port 80 health route available while TLS is corrected.

## Operational Notes

- Keep SSM as the primary management path.
- Keep SSH restricted to trusted /32 only.
- Do not enable ALB unless upgrade triggers in `tls-cost-decision.md` are met.
