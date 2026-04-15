# Production Environment

This environment is the production deployment entrypoint for the ServiceStack platform.

The production stack currently anchors the AWS baseline for:

- VPC and security group wiring
- the SSM-managed EC2 Docker host
- the managed PostgreSQL RDS instance
- shared outputs consumed by deployment and migration workflows

This entrypoint should stay focused on environment composition and verified production-safe defaults.
