variable "cluster_name" {
  description = "Base name for the Aurora DSQL cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name)) && length(var.cluster_name) <= 63
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens, and be 63 characters or less."
  }
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection for the DSQL cluster"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where the VPC endpoint will be created. If empty, uses default VPC"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Comma-separated list of subnet IDs for the VPC endpoint. If empty, uses all subnets in the VPC"
  type        = string
  default     = ""
}

variable "enable_vpc_endpoint" {
  description = "Enable VPC endpoint for private connectivity"
  type        = bool
  default     = true
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for the DSQL cluster"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Create IAM role for DSQL cluster access"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "Comma-separated list of CIDR blocks allowed to connect to DSQL cluster"
  type        = string
  default     = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
  
  validation {
    condition = can([
      for cidr in split(",", var.allowed_cidr_blocks) : 
      cidrsubnet(trimspace(cidr), 0, 0)
    ])
    error_message = "All provided CIDR blocks must be valid CIDR notation."
  }
}
