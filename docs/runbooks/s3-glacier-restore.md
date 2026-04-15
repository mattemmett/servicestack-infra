# S3 Glacier Restore For Historical Exports

This runbook covers the safe recovery workflow for archived historical export objects in the production warehouse bucket.

## Purpose

Use this workflow when older export data must be read for migration, validation, or forensic investigation and some objects have transitioned into S3 Glacier Flexible Retrieval.

Primary target at the time of writing:
- bucket: `servicestack-exports-warehouse-prod`
- prefix family: `landingdc-160426/YYYYMMDD/`

## Safety Rules

These exports are treated as irreplaceable production records.

Do:
- use read-only inspection first
- use restore requests to create a temporary accessible copy
- verify the object header status before assuming data is readable

Do not:
- delete objects
- overwrite or replace objects
- rename prefixes during recovery work
- run bulk copy operations over the source data

## Verified Findings

Verified on 2026-04-15:
- earliest dated folder found under the target prefix was `20240409`
- latest dated folder found under the target prefix was `20260414`
- Glacier-backed objects were present from `20240409` through `20260112`
- the affected objects were the historical menu export JSON files under those date folders
- 1,372 Glacier objects were identified, totaling about 1.20 GiB
- Standard restore requests were successfully queued and the sampled objects later reported a restore expiry date through `Thu, 30 Apr 2026 00:00:00 GMT`

## Recommended Retrieval Tier

Default recommendation:
- use **Standard** restores when timely recovery matters but cost should remain low

Why:
- Standard restores are much faster than Bulk for operational use
- the measured restore set was small enough that Standard remained inexpensive
- Expedited should be reserved for true urgency because the request pricing is significantly higher

## Recovery Workflow

### 1. Discover date prefixes

```bash
aws s3api list-objects-v2 \
  --bucket servicestack-exports-warehouse-prod \
  --prefix landingdc-160426/ \
  --delimiter '/'
```

### 2. Identify archived objects

```bash
aws s3api list-objects-v2 \
  --bucket servicestack-exports-warehouse-prod \
  --prefix landingdc-160426/ \
  --query 'Contents[?StorageClass==`GLACIER`].[Key,Size]' \
  --output table
```

### 3. Request a Standard restore

Example for one object:

```bash
aws s3api restore-object \
  --bucket servicestack-exports-warehouse-prod \
  --key 'landingdc-160426/20240409/MenuExport_adddeea2-4ff3-46e6-840b-5b8fa9fad1db.json' \
  --restore-request '{"Days":14,"GlacierJobParameters":{"Tier":"Standard"}}'
```

### 4. Verify restore state

```bash
aws s3api head-object \
  --bucket servicestack-exports-warehouse-prod \
  --key 'landingdc-160426/20240409/MenuExport_adddeea2-4ff3-46e6-840b-5b8fa9fad1db.json' \
  --query '{StorageClass:StorageClass,Restore:Restore}'
```

Expected states:
- `ongoing-request="true"` means the restore is still in progress
- `ongoing-request="false", expiry-date="..."` means the temporary restored copy is ready

Important note:
- the object may still report `StorageClass` as `GLACIER`; this is normal and does not mean the restore failed

## Operational Guidance

- prefer restoring only the needed scope
- if a wide date range is required, estimate object count and retrieval cost first
- keep the restore window long enough for downstream migration work to finish without repeating requests
- record the expiry date so the migration schedule stays ahead of the temporary access window
