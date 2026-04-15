# ServiceStack Infra Repo Structure Draft

This draft aligns the repo layout with the consolidation plan and the repo operating rules.

## Goals

- Keep reusable infrastructure code separate from environment-specific stacks.
- Isolate lab and prod cleanly.
- Bootstrap remote state safely before workload rollout.
- Preserve the copied legacy folder only as a temporary reference.

## Recommended Target Layout

- servicestack-infra/
  - README.md
  - docs/
    - decisions/
    - runbooks/
    - migration/
  - bootstrap/
    - state-backend/
      - main.tf
      - variables.tf
      - outputs.tf
  - modules/
    - networking/
    - security/
    - iam/
    - ec2_host/
    - rds_postgres/
    - ecr/
    - s3/
    - cloudfront_site/
    - scheduler/
    - ecs_task/
    - dns/
    - certificates/
    - ses/
    - sqs/
  - environments/
    - lab/
      - providers.tf
      - versions.tf
      - main.tf
      - variables.tf
      - outputs.tf
      - terraform.tfvars.example
    - prod/
      - providers.tf
      - versions.tf
      - main.tf
      - variables.tf
      - outputs.tf
      - terraform.tfvars.example
  - templates/
    - cloud_init/
    - nginx/
  - scripts/
  - servicestack-infrastructure/
    - legacy reference only, ignored by Git

## What Belongs Where

### bootstrap/
Use this only for the remote state backend and any one-time setup primitives needed before the main stacks can run.

### modules/
This is the reusable building block layer. Each module should have a narrow responsibility and expose stable outputs.

### environments/
This is the active entrypoint layer for deployment. These folders should compose modules together for each environment tier.

### templates/
Keep EC2 user data, nginx configs, and other rendered assets here rather than mixing them into deployment entrypoints.

### docs/
Store rollout notes, decision records, and operational runbooks here so infra changes remain auditable.

## Mapping To The Consolidation Plan

This layout directly supports the plan items for:

- VPC and networking foundations
- EC2 hosting for the backend
- RDS Postgres
- ECR repositories
- S3 and CloudFront for the Flutter web app
- EventBridge and ECS or Fargate scheduling
- Route 53 and ACM
- shared IAM
- later SES and SQS for IIP intake

## Recommended Build Order

1. Bootstrap remote state.
2. Stand up networking and shared security primitives.
3. Add RDS and its outputs.
4. Add ECR for image delivery.
5. Add EC2 host and template-driven nginx setup.
6. Add DNS and certificate resources.
7. Add S3 and CloudFront for the console frontend.
8. Add EventBridge and ECS or Fargate for nightly ETL.
9. Fold in SES and SQS when the IIP phase is ready.

## Practical Recommendation For This Repo

Do not keep building on the old flat copied layout as the active long-term structure.

Instead:

- keep servicestack-infrastructure as a legacy snapshot only
- build the real consolidated repo around modules plus environments
- move toward lab and prod entrypoints early so state isolation is clear from the start
