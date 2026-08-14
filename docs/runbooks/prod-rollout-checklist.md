# Production rollout checklist

This checklist tracks the work needed to take the current infra baseline from validated PoC state to a real production rollout path.

Before starting checklist execution, run the Local AWS Access Workflow in `README.md` to load env, refresh SSH CIDR, and verify AWS caller identity.

## Status legend

- [ ] Not started
- [x] Completed
- [ ] In progress

> Current status: AWS credentials are now configured and verified with preflight identity checks.

> App rollout note: the producer-owned exports contract is important for the long term, but it is not a blocker for the first deploy if ETL can be validated against the seeded source paths and a bounded import window.

## 1. Production inputs and readiness

- [x] Confirm the production values file exists and is populated for [environments/prod](../../environments/prod)
- [x] Confirm the database credentials exist in SSM for `/servicestack/db-user` and `/servicestack/db-password`
- [x] Confirm the SSH CIDR is restricted to a trusted source
- [x] Confirm the Route 53 zone and host naming assumptions are valid
- [x] Confirm the AMI and instance size are suitable for the planned runtime

## 2. Core production baseline

- [x] Run a production plan for [environments/prod](../../environments/prod)
- [x] Apply the production baseline for networking, security groups, EC2 host, RDS, and DNS
- [x] Capture the resulting host, RDS, and network outputs from the environment

## 3. Runtime validation on the new host

- [x] Verify SSM access to the production EC2 host
- [x] Verify Docker and Docker Compose are available on the host
- [x] Verify the host can authenticate to GHCR
- [x] Verify the host can pull the private image successfully
- [x] Verify the compose stack starts successfully
- [x] Verify the health endpoint returns success

## 4. App-to-infra contract

- [x] Define the app repo image build and publish workflow
- [x] Define the app repo image tag strategy
- [x] Define the registry credential path for the app repo
- [x] Define the deploy command contract used by the app repo
- [x] Define health-check expectations for the deployed runtime

## 5. Platform expansion after the baseline is proven

- [x] Finalize cost-first TLS decision and upgrade trigger criteria in [tls-cost-decision.md](./tls-cost-decision.md) (superseded: TLS moved to CloudFront)
- [x] Add host-level Let's Encrypt operations runbook in [tls-letsencrypt-ec2.md](./tls-letsencrypt-ec2.md) (superseded: never implemented)
- [x] Add certificate and TLS handling: ACM wildcard for `*.service-stack.io`, terminated at CloudFront
- [x] Add or confirm the registry path used for runtime images: GHCR, with a separate `servicestack-console` image for the web console
- [x] Add frontend hosting path for the web console: container image on the app host, fronted by CloudFront
- [x] Add worker/scheduler runtime: `etl-scheduler` runs in the app compose stack on the infra-managed host
- [ ] Add SES/SQS support only if the intake path remains in scope

## 6. App rollout sequence

- [x] Deploy ETL and verify a bounded backfill against the seeded source paths
- [x] Verify nightly and summary ETL jobs can run against RDS
- [x] Deploy API plus Streamlit dashboard and verify reads from RDS
- [x] Deploy Flutter console and verify it consumes the same API
- [ ] Reconcile the exports contract after the first end-to-end app deployment is proven
- [x] Define and publish the transition DNS target for the new console rollout before cutting over from `console.service-stack.io`
