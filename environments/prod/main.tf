data "aws_ssm_parameter" "db_user" {
  name = "/servicestack/db-user"
}

data "aws_ssm_parameter" "db_password" {
  name = "/servicestack/db-password"
}

locals {
  stack_name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "opentofu"
  }
}

module "networking" {
  source = "../../modules/networking"

  name_prefix              = local.stack_name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidr       = var.public_subnet_cidr
  public_availability_zone = var.public_availability_zone
  private_subnets = {
    private_a = {
      cidr_block        = var.private_subnet_a_cidr
      availability_zone = var.private_subnet_a_availability_zone
    }
    private_b = {
      cidr_block        = var.private_subnet_b_cidr
      availability_zone = var.private_subnet_b_availability_zone
    }
  }
  tags = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix       = local.stack_name
  vpc_id            = module.networking.vpc_id
  ssh_cidr_blocks   = var.ssh_cidr_blocks
  http_cidr_blocks  = var.http_cidr_blocks
  https_cidr_blocks = var.https_cidr_blocks
  tags              = local.common_tags
}

module "certificates" {
  source = "../../modules/certificates"

  name_prefix               = local.stack_name
  zone_name                 = var.route53_zone_name
  domain_name               = var.route53_zone_name
  subject_alternative_names = ["*.${var.route53_zone_name}"]
  tags                      = local.common_tags
}

module "cloudfront_site" {
  source = "../../modules/cloudfront_site"

  name_prefix         = local.stack_name
  aliases             = var.edge_aliases
  acm_certificate_arn = module.certificates.certificate_arn
  origin_domain_name  = module.ec2_host.public_dns
  tags                = local.common_tags
}

# Separate distribution: these hostnames serve dynamic responses at the root, so
# caching must be off by default rather than only on /api/*.
module "cloudfront_app" {
  source = "../../modules/cloudfront_site"

  name_prefix              = "${local.stack_name}-app"
  aliases                  = var.app_edge_aliases
  acm_certificate_arn      = module.certificates.certificate_arn
  origin_domain_name       = module.ec2_host.public_dns
  default_caching_disabled = true
  api_path_patterns        = []
  tags                     = local.common_tags
}

module "dns" {
  source = "../../modules/dns"

  zone_name = var.route53_zone_name
  records = {
    api = {
      name    = "api.service-stack.io"
      ttl     = 300
      records = [module.ec2_host.public_ip]
    }
    dashboard = {
      name    = "dashboard.service-stack.io"
      ttl     = 300
      records = [module.ec2_host.public_ip]
    }
  }

  alias_records = {
    console = {
      name                  = "console.service-stack.io"
      target_dns_name       = module.cloudfront_site.domain_name
      target_hosted_zone_id = module.cloudfront_site.hosted_zone_id
    }
    console_next = {
      name                  = "console-next.service-stack.io"
      target_dns_name       = module.cloudfront_site.domain_name
      target_hosted_zone_id = module.cloudfront_site.hosted_zone_id
    }
    # -next hostnames validate the edge before api and dashboard are cut over.
    api_next = {
      name                  = "api-next.service-stack.io"
      target_dns_name       = module.cloudfront_app.domain_name
      target_hosted_zone_id = module.cloudfront_app.hosted_zone_id
    }
    dashboard_next = {
      name                  = "dashboard-next.service-stack.io"
      target_dns_name       = module.cloudfront_app.domain_name
      target_hosted_zone_id = module.cloudfront_app.hosted_zone_id
    }
  }
}

module "ec2_host" {
  source = "../../modules/ec2_host"

  name_prefix                 = local.stack_name
  subnet_id                   = module.networking.public_subnet_id
  security_group_id           = module.security.app_security_group_id
  instance_type               = var.host_instance_type
  root_volume_size            = var.host_root_volume_size
  ami_id                      = var.host_ami_id
  associate_public_ip_address = var.host_associate_public_ip_address
  enable_exports_read_only    = var.enable_exports_read_only
  exports_bucket_arn          = var.exports_bucket_arn
  exports_object_prefixes     = var.exports_object_prefixes
  exports_kms_key_arn         = var.exports_kms_key_arn
  user_data_template_path     = "${path.root}/../../templates/cloud_init/docker-host.sh.tftpl"
  tags                        = local.common_tags
}

module "rds_postgres" {
  source = "../../modules/rds_postgres"

  name_prefix           = local.stack_name
  identifier            = var.db_identifier
  db_name               = var.db_name
  username              = data.aws_ssm_parameter.db_user.value
  password              = data.aws_ssm_parameter.db_password.value
  subnet_ids            = module.networking.private_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
  apply_immediately     = var.db_apply_immediately
  tags                  = local.common_tags
}

# This is the initial production AWS baseline.
# Higher-cost components should be added only when justified by concrete runtime needs.