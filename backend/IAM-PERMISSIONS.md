# IAM Permissions for Aurora DSQL

## Current Error

```
pq: unable to accept connection, access denied
```

This means your AWS IAM user/role doesn't have the required permissions to connect to Aurora DSQL.

## ✅ Required IAM Permissions

Your IAM user (`todo-app-deployer`) needs these permissions:

### Minimum Policy for DSQL Connection

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dsql:DbConnect"
      ],
      "Resource": "arn:aws:dsql:us-east-1:156783829256:cluster/*"
    }
  ]
}
```

### Complete Policy (Recommended)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DSQLConnect",
      "Effect": "Allow",
      "Action": [
        "dsql:DbConnect",
        "dsql:DbConnectAdmin"
      ],
      "Resource": [
        "arn:aws:dsql:us-east-1:156783829256:cluster/*"
      ]
    }
  ]
}
```

## 🔧 How to Add Permissions

### Option 1: AWS Console

1. Go to **IAM Console**: https://console.aws.amazon.com/iam/
2. Click **Users** → Find `todo-app-deployer`
3. Click **Add permissions** → **Attach policies directly**
4. Click **Create policy**
5. Choose **JSON** tab
6. Paste the policy above
7. Name it: `DSQLConnectPolicy`
8. Click **Create policy**
9. Go back and attach this policy to your user

### Option 2: AWS CLI

```bash
# Create the policy
cat > dsql-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dsql:DbConnect",
        "dsql:DbConnectAdmin"
      ],
      "Resource": "arn:aws:dsql:us-east-1:156783829256:cluster/*"
    }
  ]
}
EOF

# Create policy in AWS
aws iam create-policy \
  --policy-name DSQLConnectPolicy \
  --policy-document file://dsql-policy.json

# Attach to user
aws iam attach-user-policy \
  --user-name todo-app-deployer \
  --policy-arn arn:aws:iam::156783829256:policy/DSQLConnectPolicy
```

### Option 3: Terraform

Add this to your Terraform configuration:

```hcl
# IAM Policy for DSQL Connection
resource "aws_iam_policy" "dsql_connect" {
  name        = "DSQLConnectPolicy"
  description = "Allow connection to Aurora DSQL clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dsql:DbConnect",
          "dsql:DbConnectAdmin"
        ]
        Resource = "arn:aws:dsql:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/*"
      }
    ]
  })
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "dsql_connect" {
  user       = "todo-app-deployer"
  policy_arn = aws_iam_policy.dsql_connect.arn
}
```

## 🧪 Test Connection with Password (Temporary)

While you setup IAM permissions, you can test with password authentication:

### 1. Create Database User with Password

Connect to DSQL (you might need to do this from AWS Console or Cloud9):

```sql
CREATE USER testuser WITH PASSWORD 'YourSecurePassword123!';
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
```

### 2. Update .env

```env
# Change authentication method
AUTH_METHOD=password

# Add password
DSQL_PASSWORD=YourSecurePassword123!
DSQL_USER=testuser
```

### 3. Test Connection

```bash
cd backend
go run main.go
```

## 🔍 Verify IAM Permissions

After adding permissions, verify they're working:

```bash
# Check your IAM identity
aws sts get-caller-identity

# Try to describe DSQL clusters (this will test basic access)
aws dsql list-clusters --region us-east-1
```

## 📋 Complete IAM Policy Example

Here's a complete policy that includes all necessary permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DSQLFullAccess",
      "Effect": "Allow",
      "Action": [
        "dsql:DbConnect",
        "dsql:DbConnectAdmin",
        "dsql:DescribeCluster",
        "dsql:ListClusters",
        "dsql:GetClusterDetails"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 Quick Fix Steps

1. **Add IAM permissions** (use one of the methods above)
2. **Wait 1-2 minutes** for permissions to propagate
3. **Test again**:
   ```bash
   cd backend
   make run
   ```
4. **Check health**:
   ```bash
   curl http://localhost:8080/health
   ```

## 🔐 Security Best Practices

### For Development
- Use password authentication for quick testing
- Add IAM permissions to your user

### For Production
- **Always use IAM authentication** (more secure, no passwords to manage)
- Use IAM roles instead of users
- Restrict permissions to specific cluster ARN
- Enable CloudTrail logging for audit

## ⚠️ Common Issues

### Error: "access denied"
- **Solution**: Add `dsql:DbConnect` permission

### Error: "operation not permitted"
- **Solution**: Add `dsql:DbConnectAdmin` permission

### Error: "invalid credentials"
- **Solution**: Check AWS credentials are correct with `aws sts get-caller-identity`

## 📞 Need Help?

If you're still having issues:

1. Check CloudWatch Logs for DSQL cluster
2. Verify security group rules (if using VPC)
3. Confirm cluster is in "available" state
4. Try password authentication to isolate IAM issues

---

**Once IAM permissions are added, your backend will work perfectly!** 🚀

