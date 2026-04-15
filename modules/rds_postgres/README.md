# RDS Postgres Module

Own the managed Postgres database, subnet group, and related access controls.

Design intent:

- place the database in private subnets
- keep access tightly scoped to the approved runtime path
- expose stable connection metadata for consumer stacks
- support the migration target for historical export data once recovery and import validation are complete
