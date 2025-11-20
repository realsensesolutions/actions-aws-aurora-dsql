# 🐛 Debug: "access denied" Error

## Current Error

```
pq: unable to accept connection, access denied
```

**Good News**: The endpoint is working! The network connection succeeds, but IAM authorization is failing.

## 🔍 Debugging Steps

### Step 1: Verify AWS Identity

Check which AWS user/role you're using:

```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "156783829256",
    "Arn": "arn:aws:iam::156783829256:user/todo-app-deployer"
}
```

**Check:**
- ✅ Is this the user you expected?
- ✅ Does this user have the correct permissions?

### Step 2: Check IAM Permissions

Check if your user has DSQL permissions:

```bash
# Get your username
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | awk -F'/' '{print $NF}')

echo "Checking permissions for user: $USER_NAME"

# Check inline policies
aws iam list-user-policies --user-name $USER_NAME

# Check attached policies
aws iam list-attached-user-policies --user-name $USER_NAME
```

**Look for:**
- `DSQLConnectPolicy` or similar
- Any policy with `dsql:DbConnect` permission

### Step 3: Verify DSQL Permissions Details

If you found a policy, check its contents:

```bash
# For inline policy
aws iam get-user-policy --user-name $USER_NAME --policy-name DSQLConnectPolicy

# For attached policy, first get the ARN, then:
aws iam get-policy-version --policy-arn arn:aws:iam::ACCOUNT:policy/POLICY_NAME --version-id v1
```

**Required permissions:**
```json
{
  "Effect": "Allow",
  "Action": [
    "dsql:DbConnect"
  ],
  "Resource": "arn:aws:dsql:us-east-1:156783829256:cluster/*"
}
```

### Step 4: Check Your .env Configuration

```bash
cd backend
cat .env | grep -E "(AUTH_METHOD|DSQL_USER|DSQL_CLUSTER_ENDPOINT)"
```

**Verify:**
- `AUTH_METHOD=iam` (not password)
- `DSQL_USER=admin` (or correct user)
- `DSQL_CLUSTER_ENDPOINT` has correct endpoint

### Step 5: Check AWS Credentials

```bash
# Check if credentials are set
env | grep AWS

# Check credentials file
cat ~/.aws/credentials

# Check if using the right profile
echo $AWS_PROFILE
```

## 🔧 Solutions (Try in Order)

### Solution 1: Add IAM Permissions (Most Common)

**A. Using the automatic script:**
```bash
cd backend/scripts
./fix-iam-permissions.sh
```

**B. Manual command:**
```bash
aws iam put-user-policy \
  --user-name todo-app-deployer \
  --policy-name DSQLConnectPolicy \
  --policy-document '{
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
  }'
```

**C. AWS Console:**
1. Go to IAM → Users → `todo-app-deployer`
2. Permissions → Add inline policy
3. JSON tab, paste:
```json
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
```

**After adding permissions:**
```bash
# Wait 30-60 seconds for AWS to propagate
sleep 60

# Try again
cd backend
make run
```

### Solution 2: Use Password Authentication (Temporary Testing)

If you can't add IAM permissions immediately:

**A. Update .env:**
```env
AUTH_METHOD=password
DSQL_PASSWORD=YourSecurePassword123!
DSQL_USER=testuser
```

**B. Create database user:**
You'll need to connect to DSQL (via AWS Console or psql from EC2) and run:
```sql
CREATE USER testuser WITH PASSWORD 'YourSecurePassword123!';
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
GRANT ALL ON ALL TABLES IN SCHEMA public TO testuser;
```

### Solution 3: Check Resource ARN

The IAM policy resource must match your cluster. Get your cluster ARN:

```bash
# From GitHub Actions output
# ARN: arn:aws:dsql:us-east-1:156783829256:cluster/a1b2c3d4e5f6

# Or list clusters
aws dsql list-clusters --region us-east-1
```

Update the policy to use the specific cluster ARN:
```json
{
  "Resource": "arn:aws:dsql:us-east-1:156783829256:cluster/YOUR-CLUSTER-ID"
}
```

### Solution 4: Verify Region Match

```bash
# Check .env region
grep AWS_REGION backend/.env

# Check if cluster exists in that region
aws dsql list-clusters --region us-east-1

# Must match!
```

### Solution 5: Check if Using Correct AWS Profile

```bash
# List configured profiles
aws configure list-profiles

# Check current profile
aws configure list

# Try with explicit profile
export AWS_PROFILE=default
cd backend && make run

# Or in .env, you can't set profile, but you can verify:
aws sts get-caller-identity --profile your-profile
```

## 🧪 Complete Debug Script

Run this to get all debug information:

```bash
#!/bin/bash
echo "🔍 DSQL Connection Debug Information"
echo "===================================="
echo ""

echo "1️⃣ AWS Identity:"
aws sts get-caller-identity 2>&1
echo ""

echo "2️⃣ AWS Credentials Source:"
aws configure list
echo ""

echo "3️⃣ Current User IAM Policies:"
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')
echo "User: $USER_NAME"
aws iam list-user-policies --user-name "$USER_NAME" 2>&1
aws iam list-attached-user-policies --user-name "$USER_NAME" 2>&1
echo ""

echo "4️⃣ .env Configuration:"
cd backend 2>/dev/null
grep -E "(DSQL_CLUSTER_ENDPOINT|AWS_REGION|DSQL_USER|AUTH_METHOD)" .env 2>&1 | grep -v PASSWORD
echo ""

echo "5️⃣ DSQL Clusters in Region:"
REGION=$(grep AWS_REGION .env 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
aws dsql list-clusters --region ${REGION:-us-east-1} 2>&1
echo ""

echo "6️⃣ Network Test:"
ENDPOINT=$(grep DSQL_CLUSTER_ENDPOINT .env 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
if [ ! -z "$ENDPOINT" ]; then
    echo "Testing endpoint: $ENDPOINT"
    nslookup $ENDPOINT 2>&1 | head -5
fi
```

Save this as `debug-connection.sh` and run:

```bash
cd backend/scripts
chmod +x debug-connection.sh
./debug-connection.sh
```

## 📊 Detailed Permission Check

Create and run this script to check if you have the exact permissions needed:

```bash
#!/bin/bash
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | awk -F'/' '{print $NF}')
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGION="us-east-1"

echo "Checking DSQL permissions for: $USER_NAME"
echo ""

# Test if user can perform dsql:DbConnect
aws iam simulate-principal-policy \
  --policy-source-arn "arn:aws:iam::${ACCOUNT_ID}:user/${USER_NAME}" \
  --action-names "dsql:DbConnect" "dsql:DbConnectAdmin" \
  --resource-arns "arn:aws:dsql:${REGION}:${ACCOUNT_ID}:cluster/*"
```

## 🎯 Quick Test Matrix

| Test | Command | Expected Result |
|------|---------|-----------------|
| AWS Identity | `aws sts get-caller-identity` | Shows your account/user |
| Network | `nslookup YOUR-ENDPOINT` | Returns IP addresses |
| IAM Policies | `aws iam list-user-policies --user-name YOUR_USER` | Shows policies list |
| DSQL Access | `aws dsql list-clusters --region us-east-1` | Shows clusters or permission error |

## 🔴 Common Issues & Fixes

### Issue 1: No Policies Found
```bash
aws iam list-user-policies --user-name todo-app-deployer
# Returns: { "PolicyNames": [] }
```
**Fix**: Run `./fix-iam-permissions.sh`

### Issue 2: Wrong Resource ARN
```json
"Resource": "arn:aws:dsql:us-west-2:..."  // Wrong region
```
**Fix**: Change to `us-east-1` (or your actual region)

### Issue 3: Using Group/Role Policies
Your permissions might be through a group or role, not directly attached.

**Check groups:**
```bash
aws iam list-groups-for-user --user-name $USER_NAME
```

**Check group policies:**
```bash
aws iam list-group-policies --group-name YOUR_GROUP
```

### Issue 4: Policy Exists But Missing Action
**Check policy content:**
```bash
aws iam get-user-policy --user-name $USER_NAME --policy-name DSQLConnectPolicy
```

**Must include:**
- `dsql:DbConnect` ✅
- Optionally: `dsql:DbConnectAdmin`

## ✅ Verification After Fix

Once you've fixed the issue:

```bash
# 1. Verify permissions are added
aws iam get-user-policy --user-name todo-app-deployer --policy-name DSQLConnectPolicy

# 2. Wait for propagation (60 seconds)
sleep 60

# 3. Test connection
cd backend
make run

# 4. In another terminal
curl http://localhost:8080/health
```

**Success looks like:**
```json
{
  "success": true,
  "message": "Service is healthy",
  "data": {
    "status": "healthy",
    "database": "connected",
    "version": "1.0.0"
  }
}
```

## 💡 Still Not Working?

Share the output of these commands for further debugging:

```bash
# 1. Your identity
aws sts get-caller-identity

# 2. Your policies
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | awk -F'/' '{print $NF}')
aws iam list-user-policies --user-name $USER_NAME
aws iam list-attached-user-policies --user-name $USER_NAME

# 3. Specific policy content
aws iam get-user-policy --user-name $USER_NAME --policy-name DSQLConnectPolicy

# 4. Your .env (without passwords)
cd backend && cat .env | grep -v PASSWORD
```

