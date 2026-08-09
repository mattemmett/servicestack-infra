# Issue 001: Codify exports bucket read-only guardrail in infra

## Problem

The exports bucket read-only guardrail for the ServiceStack ETL EC2 role was verified manually and applied directly through AWS CLI, but the policy is not yet codified as a durable infra-managed contract.

That leaves the boundary vulnerable to drift if the bucket policy or role policy is changed outside the repo.

## Context

- Bucket: `arn:aws:s3:::servicestack-exports-warehouse-prod`
- ETL EC2 runtime role: `arn:aws:iam::178304346473:role/servicestack-prod-ec2-role`
- Producer Lambda writer: `arn:aws:iam::178304346473:role/servicestack-exports-lambda-role-prod`
- Bucket ownership: `BucketOwnerEnforced`
- Bucket encryption: SSE-S3 (`AES256`)

## Desired Outcome

Capture the guardrail in the repo that owns the policy boundary so the following remains true after future applies:

1. The EC2 ETL role can read approved prefixes only.
2. The EC2 ETL role cannot write or delete objects.
3. The producer Lambda writer continues to write successfully.

## Acceptance Criteria

- The policy boundary is represented in infra code or an infra-managed attachment.
- The policy is reviewed as part of the rollout checklist.
- A repeatable verification step exists for the EC2 role and producer Lambda role.
- The infra documentation notes the prefix scope and the producer-owned nature of the bucket.

## Follow-Up

- Keep the guardrail in the bucket-owning repo, not in the app repo.
- Add a CI/Ops check or runbook step that proves the deny/allow split after deploy.