variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the host will run"
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Docker host"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP with the host"
  type        = bool
  default     = true
}

variable "ami_ssm_parameter_name" {
  description = "SSM parameter name for the AMI ID"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "ami_id" {
  description = "Optional explicit AMI ID to pin the host to a known image"
  type        = string
  default     = null
}

variable "user_data_template_path" {
  description = "Path to the cloud-init or user-data template"
  type        = string
}

variable "enable_ecr_read_only" {
  description = "Attach read-only ECR access for pulling private images"
  type        = bool
  default     = true
}

variable "enable_exports_read_only" {
  description = "Attach read-only access to an external exports bucket"
  type        = bool
  default     = false
}

variable "exports_bucket_arn" {
  description = "ARN of the producer-owned exports bucket"
  type        = string
  default     = null
}

variable "exports_object_prefixes" {
  description = "Optional object key prefixes to scope read access, for example landingdc-160426/"
  type        = list(string)
  default     = []
}

variable "exports_kms_key_arn" {
  description = "Optional KMS key ARN for decrypting SSE-KMS encrypted export objects"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
