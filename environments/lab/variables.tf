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
  default = "lab"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "ssh_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
