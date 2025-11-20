#!/bin/bash

# Comprehensive debugging script for DSQL connection issues

set -e

echo "🔍 DSQL Connection Debugging Tool"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to backend directory
cd "$(dirname "$0")/.." || exit 1

echo "1️⃣ AWS Identity Check"
echo "────────────────────────────────────────"
if aws sts get-caller-identity &>/dev/null; then
    IDENTITY=$(aws sts get-caller-identity)
    USER_ARN=$(echo $IDENTITY | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    ACCOUNT_ID=$(echo $IDENTITY | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    USER_NAME=$(echo $USER_ARN | awk -F'/' '{print $NF}')
    
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
    echo "   Account ID: $ACCOUNT_ID"
    echo "   User ARN: $USER_ARN"
    echo "   User Name: $USER_NAME"
else
    echo -e "${RED}❌ AWS credentials NOT configured${NC}"
    echo "   Run: aws configure"
    exit 1
fi
echo ""

echo "2️⃣ AWS Credentials Source"
echo "────────────────────────────────────────"
aws configure list
echo ""

echo "3️⃣ IAM Policies Check"
echo "────────────────────────────────────────"
echo "Checking inline policies..."
INLINE_POLICIES=$(aws iam list-user-policies --user-name "$USER_NAME" --query 'PolicyNames' --output text 2>/dev/null)
if [ -z "$INLINE_POLICIES" ]; then
    echo -e "${YELLOW}⚠️  No inline policies found${NC}"
else
    echo -e "${GREEN}✅ Inline policies found:${NC}"
    echo "   $INLINE_POLICIES"
    
    # Check if DSQLConnectPolicy exists
    if echo "$INLINE_POLICIES" | grep -q "DSQLConnectPolicy"; then
        echo ""
        echo "📋 DSQLConnectPolicy content:"
        aws iam get-user-policy --user-name "$USER_NAME" --policy-name DSQLConnectPolicy --query 'PolicyDocument' 2>/dev/null || echo "   Could not retrieve policy"
    fi
fi

echo ""
echo "Checking attached policies..."
ATTACHED_POLICIES=$(aws iam list-attached-user-policies --user-name "$USER_NAME" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null)
if [ -z "$ATTACHED_POLICIES" ]; then
    echo -e "${YELLOW}⚠️  No attached policies found${NC}"
else
    echo -e "${GREEN}✅ Attached policies:${NC}"
    echo "   $ATTACHED_POLICIES"
fi
echo ""

echo "4️⃣ .env Configuration Check"
echo "────────────────────────────────────────"
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file found${NC}"
    echo ""
    
    ENDPOINT=$(grep DSQL_CLUSTER_ENDPOINT .env | cut -d'=' -f2 | tr -d ' ')
    REGION=$(grep AWS_REGION .env | cut -d'=' -f2 | tr -d ' ')
    USER=$(grep DSQL_USER .env | cut -d'=' -f2 | tr -d ' ')
    AUTH_METHOD=$(grep AUTH_METHOD .env | cut -d'=' -f2 | tr -d ' ')
    
    echo "   DSQL_CLUSTER_ENDPOINT: $ENDPOINT"
    echo "   AWS_REGION: $REGION"
    echo "   DSQL_USER: $USER"
    echo "   AUTH_METHOD: $AUTH_METHOD"
    
    # Validate endpoint
    if [[ $ENDPOINT == vpce-* ]]; then
        echo -e "   ${YELLOW}⚠️  Using VPC endpoint (only works from within VPC)${NC}"
    fi
else
    echo -e "${RED}❌ .env file NOT found${NC}"
    echo "   Run: cp env.example .env"
    exit 1
fi
echo ""

echo "5️⃣ Network Connectivity Check"
echo "────────────────────────────────────────"
if [ ! -z "$ENDPOINT" ]; then
    echo "Testing DNS resolution for: $ENDPOINT"
    if nslookup "$ENDPOINT" &>/dev/null; then
        echo -e "${GREEN}✅ Endpoint DNS resolves${NC}"
        nslookup "$ENDPOINT" | grep -A2 "Name:" | head -3
    else
        echo -e "${RED}❌ Endpoint DNS does NOT resolve${NC}"
        echo "   This endpoint is not accessible from your network"
    fi
else
    echo -e "${YELLOW}⚠️  No endpoint configured${NC}"
fi
echo ""

echo "6️⃣ DSQL Cluster Check"
echo "────────────────────────────────────────"
echo "Listing DSQL clusters in region: ${REGION:-us-east-1}"
if aws dsql list-clusters --region "${REGION:-us-east-1}" &>/dev/null; then
    CLUSTERS=$(aws dsql list-clusters --region "${REGION:-us-east-1}" --query 'clusters[].identifier' --output text 2>/dev/null)
    if [ -z "$CLUSTERS" ]; then
        echo -e "${YELLOW}⚠️  No clusters found in this region${NC}"
    else
        echo -e "${GREEN}✅ Clusters found:${NC}"
        echo "   $CLUSTERS"
    fi
else
    echo -e "${RED}❌ Cannot list clusters${NC}"
    echo "   This could be a permissions issue"
fi
echo ""

echo "7️⃣ Permission Simulation (if available)"
echo "────────────────────────────────────────"
echo "Simulating dsql:DbConnect permission..."
SIMULATION=$(aws iam simulate-principal-policy \
  --policy-source-arn "arn:aws:iam::${ACCOUNT_ID}:user/${USER_NAME}" \
  --action-names "dsql:DbConnect" \
  --resource-arns "arn:aws:dsql:${REGION:-us-east-1}:${ACCOUNT_ID}:cluster/*" \
  --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null)

if [ "$SIMULATION" = "allowed" ]; then
    echo -e "${GREEN}✅ dsql:DbConnect permission: ALLOWED${NC}"
elif [ "$SIMULATION" = "denied" ] || [ "$SIMULATION" = "implicitDeny" ]; then
    echo -e "${RED}❌ dsql:DbConnect permission: DENIED${NC}"
    echo "   This is why you're getting 'access denied'"
else
    echo -e "${YELLOW}⚠️  Could not simulate permissions${NC}"
fi
echo ""

echo "════════════════════════════════════════"
echo "📊 DIAGNOSIS"
echo "════════════════════════════════════════"
echo ""

# Determine the issue
ISSUES_FOUND=0

if [ "$SIMULATION" = "denied" ] || [ "$SIMULATION" = "implicitDeny" ]; then
    echo -e "${RED}❌ ISSUE: Missing DSQL IAM Permissions${NC}"
    echo ""
    echo "   Your user '$USER_NAME' does not have dsql:DbConnect permission"
    echo ""
    echo "   FIX: Run this command to add permissions:"
    echo "   ./scripts/fix-iam-permissions.sh"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [[ $ENDPOINT == vpce-* ]]; then
    echo -e "${YELLOW}⚠️  WARNING: Using VPC Endpoint${NC}"
    echo ""
    echo "   VPC endpoints only work from within the AWS VPC"
    echo "   For local development, use the public endpoint from GitHub Actions"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if ! nslookup "$ENDPOINT" &>/dev/null; then
    echo -e "${RED}❌ ISSUE: Endpoint Not Reachable${NC}"
    echo ""
    echo "   The endpoint '$ENDPOINT' cannot be reached from your network"
    echo "   Check that you're using the PUBLIC endpoint for local development"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ "$AUTH_METHOD" = "password" ]; then
    echo -e "${YELLOW}ℹ️  INFO: Using Password Authentication${NC}"
    echo ""
    echo "   Make sure DSQL_PASSWORD is set in your .env file"
    echo "   For better security, consider using AUTH_METHOD=iam"
    echo ""
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious issues found!${NC}"
    echo ""
    echo "If you're still getting errors, try:"
    echo "1. Wait 60 seconds for AWS IAM changes to propagate"
    echo "2. Check CloudWatch Logs for the DSQL cluster"
    echo "3. Verify the database user exists in DSQL"
    echo ""
fi

echo "════════════════════════════════════════"
echo ""
echo "For more help, see:"
echo "  - backend/DEBUG-ACCESS-DENIED.md"
echo "  - backend/IAM-PERMISSIONS.md"
echo "  - backend/CONFIGURACION-ENV.md"
echo ""

