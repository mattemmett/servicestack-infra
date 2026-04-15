variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "public_availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets used for internal tiers such as databases"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
