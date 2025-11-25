output "cluster_arn" {
  description = "ARN of the Aurora DSQL cluster"
  value       = aws_dsql_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Public endpoint of the Aurora DSQL cluster"
  value       = aws_dsql_cluster.main.endpoint
}

output "vpc_endpoint_id" {
  description = "ID of the VPC endpoint (if created)"
  value       = var.enable_vpc_endpoint ? aws_vpc_endpoint.dsql[0].id : null
}

output "vpc_endpoint_dns_name" {
  description = "DNS name of the VPC endpoint (if created)"
  value       = var.enable_vpc_endpoint ? aws_vpc_endpoint.dsql[0].dns_entry[0].dns_name : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption (if created)"
  value       = var.enable_kms_encryption ? aws_kms_key.dsql[0].arn : null
}

output "kms_key_id" {
  description = "ID of the KMS key used for encryption (if created)"
  value       = var.enable_kms_encryption ? aws_kms_key.dsql[0].key_id : null
}

output "iam_role_arn" {
  description = "ARN of the IAM role for DSQL access (if created)"
  value       = var.create_iam_role ? aws_iam_role.dsql_cluster_admin[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for DSQL access (if created)"
  value       = var.create_iam_role ? aws_iam_role.dsql_cluster_admin[0].name : null
}

output "security_group_id" {
  description = "ID of the security group for VPC endpoint (if created)"
  value       = var.enable_vpc_endpoint ? aws_security_group.dsql_vpc_endpoint[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group for VPC endpoint (if created)"
  value       = var.enable_vpc_endpoint ? aws_security_group.dsql_vpc_endpoint[0].arn : null
}

# Note: cluster_identifier attribute availability needs verification
# Uncomment once correct attribute name is confirmed
# output "cluster_identifier" {
#   description = "Identifier of the Aurora DSQL cluster"  
#   value       = aws_dsql_cluster.main.cluster_identifier
# }

output "vpc_endpoint_service_name" {
  description = "VPC endpoint service name for the Aurora DSQL cluster"
  value       = aws_dsql_cluster.main.vpc_endpoint_service_name
}
