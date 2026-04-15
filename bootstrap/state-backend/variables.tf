variable "aws_region" {
  description = "AWS region for the remote state backend"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for remote state"
  type        = string
}

variable "lock_table_name" {
  description = "Optional lock table name for state coordination"
  type        = string
  default     = "servicestack-opentofu-locks"
}
