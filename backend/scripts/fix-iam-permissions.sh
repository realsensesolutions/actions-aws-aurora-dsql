#!/bin/bash

# Script to fix IAM permissions for Aurora DSQL connection

set -e

echo "🔧 Fixing IAM Permissions for Aurora DSQL"
echo "=========================================="
echo ""

# Get current AWS identity
echo "📋 Checking AWS identity..."
IDENTITY=$(aws sts get-caller-identity 2>&1)

if [ $? -ne 0 ]; then
    echo "❌ Error: AWS credentials not configured"
    echo "   Run: aws configure"
    exit 1
fi

USER_ARN=$(echo $IDENTITY | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
ACCOUNT_ID=$(echo $IDENTITY | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
USER_NAME=$(echo $USER_ARN | awk -F'/' '{print $NF}')

echo "✅ AWS Identity:"
echo "   Account: $ACCOUNT_ID"
echo "   User: $USER_NAME"
echo ""

# Get AWS region from .env or use default
if [ -f ".env" ]; then
    AWS_REGION=$(grep AWS_REGION .env | cut -d'=' -f2 | tr -d ' ')
else
    AWS_REGION="us-east-1"
fi

echo "📝 Creating IAM policy for DSQL connection..."
echo ""

# Create the policy
POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dsql:DbConnect",
        "dsql:DbConnectAdmin"
      ],
      "Resource": "arn:aws:dsql:${AWS_REGION}:${ACCOUNT_ID}:cluster/*"
    }
  ]
}
EOF
)

# Try to attach inline policy to user
echo "🔒 Attaching policy to user: $USER_NAME"
echo ""

aws iam put-user-policy \
  --user-name "$USER_NAME" \
  --policy-name "DSQLConnectPolicy" \
  --policy-document "$POLICY_DOCUMENT" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Success!"
    echo "=========================================="
    echo ""
    echo "IAM permissions have been added to user: $USER_NAME"
    echo ""
    echo "Policy added:"
    echo "  - dsql:DbConnect"
    echo "  - dsql:DbConnectAdmin"
    echo ""
    echo "Resource: arn:aws:dsql:${AWS_REGION}:${ACCOUNT_ID}:cluster/*"
    echo ""
    echo "Next steps:"
    echo "  1. Wait ~1 minute for permissions to propagate"
    echo "  2. Run: make run"
    echo "  3. Test: curl http://localhost:8080/health"
    echo ""
else
    echo ""
    echo "❌ Failed to attach policy"
    echo ""
    echo "This might be because:"
    echo "  1. You don't have permissions to modify IAM policies"
    echo "  2. The user is managed by an administrator"
    echo ""
    echo "Alternative: Ask your AWS administrator to add these permissions:"
    echo ""
    echo "$POLICY_DOCUMENT"
    echo ""
    exit 1
fi

