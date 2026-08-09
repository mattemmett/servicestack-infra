data "aws_ssm_parameter" "al2023_ami" {
  name = var.ami_ssm_parameter_name
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  normalized_exports_prefixes = [
    for prefix in var.exports_object_prefixes : trimsuffix(trimprefix(trimspace(prefix), "/"), "/")
    if trimspace(prefix) != ""
  ]

  exports_object_arns = var.enable_exports_read_only && var.exports_bucket_arn != null ? (
    length(local.normalized_exports_prefixes) > 0 ? [
      for prefix in local.normalized_exports_prefixes : "${var.exports_bucket_arn}/${prefix}*"
    ] : ["${var.exports_bucket_arn}/*"]
  ) : []

  exports_list_prefixes = var.enable_exports_read_only && var.exports_bucket_arn != null && length(local.normalized_exports_prefixes) > 0 ? [
    for prefix in local.normalized_exports_prefixes : "${prefix}*"
  ] : []
}

data "aws_iam_policy_document" "exports_read_only" {
  count = var.enable_exports_read_only && var.exports_bucket_arn != null ? 1 : 0

  statement {
    sid = "ExportsListBucket"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.exports_bucket_arn
    ]

    dynamic "condition" {
      for_each = length(local.exports_list_prefixes) > 0 ? [1] : []

      content {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = local.exports_list_prefixes
      }
    }
  }

  statement {
    sid = "ExportsGetObject"

    actions = [
      "s3:GetObject"
    ]

    resources = local.exports_object_arns
  }

  dynamic "statement" {
    for_each = var.exports_kms_key_arn != null ? [1] : []

    content {
      sid = "ExportsKmsDecrypt"

      actions = [
        "kms:Decrypt"
      ]

      resources = [
        var.exports_kms_key_arn
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  count = var.enable_ecr_read_only ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "exports_read_only" {
  count = var.enable_exports_read_only && var.exports_bucket_arn != null ? 1 : 0

  name   = "${var.name_prefix}-exports-read-only"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.exports_read_only[0].json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-profile"
  })
}

resource "aws_instance" "this" {
  ami                         = coalesce(var.ami_id, data.aws_ssm_parameter.al2023_ami.value)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = templatefile(var.user_data_template_path, {})
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-host"
  })
}
