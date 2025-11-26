# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get VPC information
data "aws_vpc" "main" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

locals {
  vpc_id         = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
  vpc_cidr_block = var.vpc_id != "" ? data.aws_vpc.main[0].cidr_block : data.aws_vpc.default[0].cidr_block
  allowed_cidrs  = split(",", var.allowed_cidr_blocks)

  # When subnet_ids is provided by user, use those directly
  # When not provided, filter to get unique subnets (one per AZ) to avoid DuplicateSubnetsInSameZone error
  user_provided_subnets = var.subnet_ids != "" ? split(",", var.subnet_ids) : []

  # Create a map of AZ -> list of subnet IDs, then take first subnet from each AZ
  az_to_subnets = {
    for subnet in data.aws_subnet.details :
    subnet.availability_zone => subnet.id...
  }

  # Get one subnet per availability zone (first found in each AZ)
  unique_subnets_per_az = [
    for az, subnet_ids in local.az_to_subnets : subnet_ids[0]
  ]

  # Final subnet list: use user-provided if available, otherwise use unique per AZ
  subnet_ids_list = length(local.user_provided_subnets) > 0 ? local.user_provided_subnets : local.unique_subnets_per_az
}

# Get all subnets in the VPC
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Get details of each subnet to determine its availability zone
data "aws_subnet" "details" {
  for_each = toset(data.aws_subnets.selected.ids)
  id       = each.value
}

# KMS key for DSQL encryption
resource "aws_kms_key" "dsql" {
  count                   = var.enable_kms_encryption ? 1 : 0
  description             = "KMS key for Aurora DSQL cluster ${var.cluster_name}"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowKeyUseServiceDSQL"
        Effect = "Allow"
        Principal = {
          Service = "dsql.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-dsql-kms"
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-aurora-dsql"
  }
}

resource "aws_kms_alias" "dsql" {
  count         = var.enable_kms_encryption ? 1 : 0
  name          = "alias/${var.cluster_name}-dsql"
  target_key_id = aws_kms_key.dsql[0].key_id
}

# Aurora DSQL Cluster
resource "aws_dsql_cluster" "main" {
  deletion_protection_enabled = var.deletion_protection_enabled

  kms_encryption_key = var.enable_kms_encryption ? aws_kms_key.dsql[0].arn : null

  tags = {
    Name        = var.cluster_name
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-aurora-dsql"
  }
}

# Security Group for VPC Endpoint
resource "aws_security_group" "dsql_vpc_endpoint" {
  count       = var.enable_vpc_endpoint ? 1 : 0
  name        = "${var.cluster_name}-dsql-vpce-sg"
  description = "VPC endpoint Aurora DSQL security group"
  vpc_id      = local.vpc_id

  tags = {
    Name        = "${var.cluster_name}-dsql-vpce-sg"
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-aurora-dsql"
  }
}

# Security Group Rules for PostgreSQL port 5432
resource "aws_vpc_security_group_ingress_rule" "dsql_inbound_postgres" {
  count             = var.enable_vpc_endpoint ? length(local.allowed_cidrs) : 0
  security_group_id = aws_security_group.dsql_vpc_endpoint[0].id
  cidr_ipv4         = trimspace(local.allowed_cidrs[count.index])
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432

  tags = {
    Name = "${var.cluster_name}-dsql-postgres-${count.index}"
  }
}

resource "aws_vpc_security_group_egress_rule" "dsql_outbound" {
  count             = var.enable_vpc_endpoint ? 1 : 0
  security_group_id = aws_security_group.dsql_vpc_endpoint[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

  tags = {
    Name = "${var.cluster_name}-dsql-outbound"
  }
}

# VPC Endpoint for DSQL
resource "aws_vpc_endpoint" "dsql" {
  count             = var.enable_vpc_endpoint ? 1 : 0
  vpc_id            = local.vpc_id
  service_name      = aws_dsql_cluster.main.vpc_endpoint_service_name
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.subnet_ids_list

  security_group_ids = [aws_security_group.dsql_vpc_endpoint[0].id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.cluster_name}-dsql-vpce"
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-aurora-dsql"
  }
}

# IAM role for DSQL cluster access
resource "aws_iam_role" "dsql_cluster_admin" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.cluster_name}-dsql-cluster-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-dsql-admin"
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-aurora-dsql"
  }
}

resource "aws_iam_role_policy" "dsql_cluster_admin" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.cluster_name}-dsql-cluster-admin-perms"
  role  = aws_iam_role.dsql_cluster_admin[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dsql:GetCluster",
          "dsql:ListClusters"
        ]
        Resource = aws_dsql_cluster.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dsql:DbConnectAdmin"
        ]
        Resource = aws_dsql_cluster.main.arn
      }
    ]
  })
}
