locals {
  stack_name = "${var.project_name}-${var.environment}"
}

# The lab environment is self-hosted in the physical home lab using Docker hosts and MinIO.
# It is not currently provisioned as AWS infrastructure from this repo.
# Keep this entrypoint as a placeholder for lab-specific configuration until explicit
# automation is needed for the self-hosted environment.
