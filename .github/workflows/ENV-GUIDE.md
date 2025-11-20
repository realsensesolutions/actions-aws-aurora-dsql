# Environment Variables Guide for action.yml

This guide explains all environment variables needed to test your `action.yml`.

## 🎯 Required Environment Variables

The `action.yml` requires these environment variables to be set by the **workflow that calls it**:

### 1. **TF_BACKEND_s3** (Set by backend setup action)
- **Description:** S3 bucket name for Terraform state storage
- **Set by:** `alonch/actions-aws-backend-setup@main` action
- **Used in:** `action.yml` line 78

```yaml
terraform init \
  -backend-config="bucket=${{ env.TF_BACKEND_s3 }}"
```

### 2. **TF_BACKEND_dynamodb** (Set by backend setup action)
- **Description:** DynamoDB table name for Terraform state locking
- **Set by:** `alonch/actions-aws-backend-setup@main` action
- **Used in:** `action.yml` line 80

```yaml
terraform init \
  -backend-config="dynamodb_table=${{ env.TF_BACKEND_dynamodb }}"
```

---

## 📍 Where to Set Environment Variables

### **Option 1: In the Workflow File** (Recommended)

```yaml
env:
  # Your custom variables
  CLUSTER_NAME: test-dsql-cluster
  AWS_REGION: us-east-1
  ENVIRONMENT: production
  
  # Backend variables (optional - usually set by backend setup action)
  # TF_BACKEND_s3: my-terraform-state-bucket
  # TF_BACKEND_dynamodb: my-terraform-lock-table
```

### **Option 2: GitHub Repository Variables**

1. Go to: **Repository → Settings → Secrets and variables → Actions → Variables**
2. Click **"New repository variable"**
3. Add variables:
   - `AWS_REGION` = `us-east-1`
   - `CLUSTER_NAME` = `my-dsql-cluster`
4. Use in workflow: `${{ vars.AWS_REGION }}`

### **Option 3: GitHub Secrets** (For sensitive data)

1. Go to: **Repository → Settings → Secrets and variables → Actions → Secrets**
2. Click **"New repository secret"**
3. Add secrets:
   - `AWS_ROLE_ARN` = `arn:aws:iam::123456789012:role/github-role`

---

## 🔧 Complete Workflow Example

```yaml
name: Test Action

on:
  workflow_dispatch:

# STEP 1: Set environment variables here
env:
  CLUSTER_NAME: test-dsql-cluster
  AWS_REGION: us-east-1

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      # STEP 2: Configure AWS
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: ${{ env.AWS_REGION }}
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      
      # STEP 3: Setup Terraform Backend
      # This sets TF_BACKEND_s3 and TF_BACKEND_dynamodb automatically
      - name: Setup Terraform Backend
        uses: alonch/actions-aws-backend-setup@main
        with:
          instance: ${{ env.CLUSTER_NAME }}
      
      # STEP 4: Call your action.yml
      - name: Create DSQL Cluster
        uses: ./  # Calls action.yml in repo root
        with:
          name: ${{ env.CLUSTER_NAME }}
          action: apply
          deletion_protection_enabled: 'false'
          enable_vpc_endpoint: 'true'
          enable_kms_encryption: 'true'
          create_iam_role: 'true'
```

---

## 📊 How Variables Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Workflow File (.github/workflows/test-action.yml)        │
│    env:                                                      │
│      CLUSTER_NAME: test-dsql                                │
│      AWS_REGION: us-east-1                                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Backend Setup Action (alonch/actions-aws-backend-setup)  │
│    Creates and exports:                                      │
│      - TF_BACKEND_s3=terraform-state-bucket                 │
│      - TF_BACKEND_dynamodb=terraform-lock-table             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Your Action (./action.yml)                               │
│    Uses these env vars:                                      │
│      - TF_BACKEND_s3 (from step 2)                          │
│      - TF_BACKEND_dynamodb (from step 2)                    │
│    Converts inputs to:                                       │
│      - TF_VAR_cluster_name=${{ inputs.name }}               │
│      - TF_VAR_deletion_protection_enabled=...               │
│      - etc.                                                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Terraform (main.tf, variables.tf, etc.)                  │
│    Reads:                                                    │
│      - var.cluster_name (from TF_VAR_cluster_name)          │
│      - var.deletion_protection_enabled                       │
│      - Backend config (S3 bucket, DynamoDB table)           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start Checklist

- [ ] **Set AWS_ROLE_ARN secret** in GitHub
- [ ] **Configure env variables** in workflow file:
  - `CLUSTER_NAME`
  - `AWS_REGION`
- [ ] **Add backend setup step** (sets TF_BACKEND_* vars automatically)
- [ ] **Call your action** with `uses: ./`
- [ ] **Configure action inputs** (name, action, etc.)

---

## 📝 All Available Inputs (for action.yml)

Configure these in the `with:` section when calling the action:

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | **required** | Cluster name |
| `action` | string | `apply` | `apply`, `plan`, or `destroy` |
| `deletion_protection_enabled` | string | `true` | `'true'` or `'false'` |
| `vpc_id` | string | default VPC | VPC ID |
| `subnet_ids` | string | all subnets | Comma-separated subnet IDs |
| `enable_vpc_endpoint` | string | `true` | Enable VPC endpoint |
| `enable_kms_encryption` | string | `true` | Enable KMS encryption |
| `create_iam_role` | string | `true` | Create IAM role |
| `allowed_cidr_blocks` | string | private ranges | Comma-separated CIDR blocks |

---

## 💡 Tips

1. **Don't hardcode TF_BACKEND_* vars** - Let the backend setup action create them
2. **Use `${{ env.VAR }}` syntax** to reference env vars in workflow
3. **Use `${{ secrets.VAR }}` syntax** for sensitive data like AWS_ROLE_ARN
4. **Use `${{ vars.VAR }}` syntax** for repository variables
5. **Test locally first** with `action: plan` before running `apply`

---

## 🐛 Common Issues

### Issue: "Error: Backend configuration required"
**Solution:** Make sure the backend setup step runs before your action:

```yaml
- name: Setup Terraform Backend
  uses: alonch/actions-aws-backend-setup@main
  with:
    instance: ${{ env.CLUSTER_NAME }}
```

### Issue: "Error: AWS credentials not configured"
**Solution:** Ensure AWS credentials step comes before your action:

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-region: ${{ env.AWS_REGION }}
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
```

### Issue: "TF_BACKEND_s3: unbound variable"
**Solution:** The backend setup action didn't run or failed. Check its logs.

