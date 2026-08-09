# Runtime Env Contract

Purpose: preserve the monorepo `.env.dev` variable model while running on the infra-managed production host.

## How The App Repo Learns Values

The app repo should not guess infrastructure values.

- Nonsecret infrastructure values come from Terraform outputs in `servicestack-infra`.
- Another repo can read those outputs through `terraform_remote_state` when it needs to wire deploy-time settings.
- Secret values, especially database credentials, come from SSM parameters and are injected into runtime env files, not stored in source control.
- Runtime env files are rendered from those inputs and uploaded to the host through the SSM deploy helpers.
- Read-only exports source values are provided through the runtime env file or remote-state/SSM contract, not by hardcoding them into app code.

## Concrete Reading Model

Think of the handoff in three layers:

1. **Terraform outputs** - values that infra publishes for consumers, such as `vpc_id`, `host_instance_id`, `host_public_ip`, `rds_endpoint`, and `route53_record_fqdns`.
2. **Remote state** - another repo can read those outputs with a `terraform_remote_state` data source if it needs to build on top of infra.
3. **SSM parameters / runtime env** - secrets and runtime credentials are injected at deploy time, not read from Terraform state in app code.

### Exact remote state location

The production infrastructure state is stored in:

- bucket: `servicestack-tfstate`
- key: `environments/prod/terraform.tfstate`
- region: `us-east-1`
- lock table: `servicestack-tfstate-locks`

That means the app repo can read prod outputs by pointing `terraform_remote_state` at the same bucket and key.

Example consumer pattern in the app repo:

```hcl
data "terraform_remote_state" "infra" {
	backend = "s3"
	config = {
		bucket = "servicestack-tfstate"
		key    = "environments/prod/terraform.tfstate"
		region = "us-east-1"
	}
}

output "host_public_ip" {
	value = data.terraform_remote_state.infra.outputs.host_public_ip
}
```

That lets the app repo consume infra values without duplicating them.

## Source Template

- `templates/compose/.env.servicestack.runtime.example`

This template keeps the same key families used in the old app runtime:

- DB settings (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`)
- AWS settings (`AWS_REGION`, `AWS_DEFAULT_REGION`)
- ETL source settings (`S3_BUCKET_NAME`, `S3_LOCATION_PREFIX`)
- canonical scope settings (`SERVICESTACK_ACCOUNT_CODE`, `SERVICESTACK_COMPANY_CODE`, `SERVICESTACK_LOCATION_CODE`)
- API and dashboard settings (`API_PORT`, `API_HOST_URL`, `DASHBOARD_PORT`)

## URL Contract

- Production API DNS target: `api.service-stack.io`
- Production dashboard DNS target: `dashboard.service-stack.io`
- Temporary transition console target: `console-next.service-stack.io`
- Current legacy console bridge: `console.service-stack.io` stays on the old host until the cutover is explicitly scheduled.
- The app should target `console-next.service-stack.io` during transition, then cut over `console.service-stack.io` when the new console is validated.

## Host Upload

Use the helper script to upload a local env file onto the managed host:

```bash
AWS_REGION=us-east-1 \
bash scripts/push-env-to-host.sh i-0eec1257722b6b1c9 /path/to/.env.runtime.local
```

Defaults:

- host app directory: `/opt/servicestack/app`
- target env filename: `.env`

Optional overrides:

- `APP_DIR=/opt/servicestack/app`
- `ENV_TARGET_FILE=.env.prod`

## Deployment Link

The deploy helper reads this file via:

- `scripts/deploy-via-ssm.sh` with `ENV_FILE` (default `.env`)

If you upload as `.env.prod`, deploy with:

```bash
ENV_FILE=.env.prod bash scripts/deploy-via-ssm.sh <instance-id>
```

## Secrets Guidance

- Keep real env files out of source control.
- Prefer SSM/secret managers as source values, then render and upload the runtime env file.
- Never store PATs or database passwords in committed files.
