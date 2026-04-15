output "stack_name" {
  value = local.stack_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_id" {
  value = module.networking.public_subnet_id
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "app_security_group_id" {
  value = module.security.app_security_group_id
}

output "rds_security_group_id" {
  value = module.security.rds_security_group_id
}

output "host_instance_id" {
  value = module.ec2_host.instance_id
}

output "host_public_ip" {
  value = module.ec2_host.public_ip
}

output "host_public_dns" {
  value = module.ec2_host.public_dns
}

output "host_private_ip" {
  value = module.ec2_host.private_ip
}

output "rds_endpoint" {
  value = module.rds_postgres.db_endpoint
}

output "rds_port" {
  value = module.rds_postgres.db_port
}

output "rds_instance_id" {
  value = module.rds_postgres.db_instance_id
}
