# AWS Aurora DSQL GitHub Action

This GitHub Action creates an AWS Aurora DSQL (Distributed SQL) serverless database cluster using Terraform with backend state management.

## Description

Amazon Aurora DSQL is a serverless, distributed SQL database engineered for high availability, strong consistency, and unlimited scalability without manual provisioning or database sharding. This action automates the deployment of:

- Aurora DSQL cluster with optional deletion protection
- KMS encryption key for data encryption 
- VPC endpoint for private connectivity
- Security group with PostgreSQL port (5432) access rules
- IAM role for database access permissions

## Prerequisites

### AWS Requirements
- AWS CLI configured or AWS credentials available
- IAM permissions for:
  - DSQL cluster creation (`dsql:*`)
  - KMS key creation and management (`kms:*`)
  - VPC endpoint creation (`ec2:CreateVpcEndpoint`, `ec2:DescribeVpcEndpoints`)
  - Security group creation (`ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`)
  - IAM role creation (`iam:CreateRole`, `iam:PutRolePolicy`)

### Region Availability
Aurora DSQL is available in select AWS regions. Verify that your target region supports Aurora DSQL before deployment.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `name` | Base name for the Aurora DSQL cluster | `true` | - |
| `action` | Desired outcome: apply, plan or destroy | `false` | `apply` |
| `deletion_protection_enabled` | Enable deletion protection for the DSQL cluster | `false` | `true` |
| `vpc_id` | VPC ID where the VPC endpoint will be created. If not provided, uses default VPC | `false` | - |
| `subnet_ids` | Comma-separated list of subnet IDs for the VPC endpoint. If not provided, uses all subnets in the VPC | `false` | - |
| `enable_vpc_endpoint` | Enable VPC endpoint for private connectivity | `false` | `true` |
| `enable_kms_encryption` | Enable KMS encryption for the DSQL cluster | `false` | `true` |
| `create_iam_role` | Create IAM role for DSQL cluster access | `false` | `true` |
| `allowed_cidr_blocks` | Comma-separated list of CIDR blocks allowed to connect to DSQL cluster | `false` | `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | ARN of the Aurora DSQL cluster |
| `cluster_id` | ID of the Aurora DSQL cluster |
| `cluster_endpoint` | Endpoint of the Aurora DSQL cluster (via VPC endpoint DNS name) |
| `vpc_endpoint_service_name` | VPC endpoint service name for the Aurora DSQL cluster |
| `vpc_endpoint_id` | ID of the VPC endpoint (if created) |
| `vpc_endpoint_dns_name` | DNS name of the VPC endpoint (if created) |
| `kms_key_arn` | ARN of the KMS key used for encryption (if created) |
| `iam_role_arn` | ARN of the IAM role for DSQL access (if created) |
| `security_group_id` | ID of the security group for VPC endpoint |

## Example Usage

```yaml
name: Deploy Aurora DSQL

on:
  push:
    branches: [main]

jobs:
  deploy:
    permissions:
      id-token: write # Required for AWS authentication
      contents: read
      
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-region: us-east-1
        role-to-assume: ${{ secrets.ROLE_ARN }}
        role-session-name: ${{ github.actor }}
    
    - name: Setup Terraform Backend
      uses: alonch/actions-aws-backend-setup@main
      with: 
        instance: my-dsql-backend

    - name: Create Aurora DSQL Cluster
      uses: realsensesolutions/actions-aws-aurora-dsql@main
      id: dsql
      with:
        name: my-aurora-dsql
        action: apply
        deletion_protection_enabled: 'true'
        enable_vpc_endpoint: 'true'
        enable_kms_encryption: 'true'
        create_iam_role: 'true'
        allowed_cidr_blocks: '10.0.0.0/8'
    
    - name: Use outputs
      run: |
        echo "Cluster endpoint: ${{ steps.dsql.outputs.cluster_endpoint }}"
```

## Connecting to Aurora DSQL

Aurora DSQL connections work through VPC endpoints rather than direct cluster endpoints. Once deployed, you can connect using:

1. **PostgreSQL-compatible clients** (DBeaver, psql, etc.)
2. **Connection details**:
   - Host: Use the `cluster_endpoint` output (this is the VPC endpoint DNS name)
   - Port: 5432
   - Database: postgres
   - Username: admin
   - Password: Generate authentication token using AWS CLI

**Note**: The `cluster_endpoint` output provides the VPC endpoint DNS name, which is the actual connection endpoint for Aurora DSQL. If VPC endpoint is disabled, the cluster_endpoint will be null as Aurora DSQL requires VPC endpoints for connectivity.

### Generate Authentication Token

```bash
aws dsql generate-db-connect-admin-auth-token \
    --hostname <cluster_endpoint> \
    --region <aws_region>
```

## Important Notes

- Aurora DSQL enforces SSL connections (SSLMODE=require)
- Authentication tokens are short-lived and must be regenerated regularly
- The service is currently available in select AWS regions
- Pricing is based on read/write operations and storage usage

## Limitations

- Limited PostgreSQL compatibility (subset of PostgreSQL 16 features)
- Region availability constraints
- Higher cost compared to single-region databases
- Some PostgreSQL extensions may not be supported

## Resources Created

This action creates the following AWS resources:

1. **aws_dsql_cluster** - The Aurora DSQL cluster
2. **aws_kms_key** - KMS key for encryption (optional)
3. **aws_vpc_endpoint** - VPC endpoint for private access (optional)
4. **aws_security_group** - Security group for VPC endpoint (optional)
5. **aws_iam_role** - IAM role for database access (optional)

## License

This project is licensed under the Apache License 2.0.
