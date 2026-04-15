locals {
  stack_name = "${var.project_name}-${var.environment}"
}

# Compose reusable modules here as the production stack grows.
# Example future layers:
# - networking
# - security
# - iam
# - rds_postgres
# - ec2_host
# - ecr
# - dns
