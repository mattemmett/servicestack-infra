variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "servicestack"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.30.1.0/24"
}

variable "public_availability_zone" {
  type    = string
  default = "us-east-1b"
}

variable "private_subnet_a_cidr" {
  type    = string
  default = "10.30.11.0/24"
}

variable "private_subnet_b_cidr" {
  type    = string
  default = "10.30.12.0/24"
}

variable "private_subnet_a_availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "private_subnet_b_availability_zone" {
  type    = string
  default = "us-east-1b"
}

variable "ssh_cidr_blocks" {
  type    = list(string)
  default = []

  validation {
    condition     = alltrue([for cidr in var.ssh_cidr_blocks : cidr != "0.0.0.0/0"])
    error_message = "Do not allow SSH from 0.0.0.0/0 in production. Use a trusted CIDR like your public IP /32."
  }
}

variable "http_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "host_instance_type" {
  type    = string
  default = "t3.small"
}

variable "host_root_volume_size" {
  type    = number
  default = 30
}

variable "host_associate_public_ip_address" {
  type    = bool
  default = true
}

variable "db_identifier" {
  type    = string
  default = "servicestack-prod"
}

variable "db_name" {
  type    = string
  default = "servicestack"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "db_apply_immediately" {
  type    = bool
  default = false
}
