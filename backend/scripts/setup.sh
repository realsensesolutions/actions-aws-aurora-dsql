#!/bin/bash

# Setup script for Aurora DSQL Test API
# This script helps you set up the backend application

set -e

echo "🚀 Aurora DSQL Test API Setup"
echo "=============================="
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or higher."
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}')
echo "✅ Go is installed: $GO_VERSION"
echo ""

# Check if we're in the backend directory
if [ ! -f "go.mod" ]; then
    echo "❌ Error: Please run this script from the backend directory"
    echo "   cd backend && ./scripts/setup.sh"
    exit 1
fi

# Step 1: Create .env file if it doesn't exist
echo "📝 Step 1: Setting up environment file..."
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        echo "✅ Created .env file from env.example"
        echo "⚠️  Please edit .env and add your DSQL_CLUSTER_ENDPOINT"
        echo ""
    else
        echo "❌ env.example file not found"
        exit 1
    fi
else
    echo "✅ .env file already exists"
    echo ""
fi

# Step 2: Install Go dependencies
echo "📦 Step 2: Installing Go dependencies..."
go mod download
echo "✅ Dependencies installed"
echo ""

# Step 3: Install swag for Swagger documentation
echo "📚 Step 3: Installing Swagger generator..."
if ! command -v swag &> /dev/null; then
    go install github.com/swaggo/swag/cmd/swag@latest
    echo "✅ Swagger generator installed"
else
    echo "✅ Swagger generator already installed"
fi
echo ""

# Step 4: Generate Swagger documentation
echo "📖 Step 4: Generating Swagger documentation..."
# Try to find swag in common locations
if command -v swag &> /dev/null; then
    swag init -g main.go --output ./docs
elif [ -f "$HOME/go/bin/swag" ]; then
    $HOME/go/bin/swag init -g main.go --output ./docs
elif [ -f "$(go env GOPATH)/bin/swag" ]; then
    $(go env GOPATH)/bin/swag init -g main.go --output ./docs
else
    echo "⚠️  Could not find swag binary. Trying with full path..."
    $(go env GOPATH)/bin/swag init -g main.go --output ./docs 2>/dev/null || echo "⚠️  Please add $(go env GOPATH)/bin to your PATH and run: swag init -g main.go --output ./docs"
fi
echo "✅ Swagger documentation generated"
echo ""

# Step 5: Check AWS credentials
echo "🔐 Step 5: Checking AWS credentials..."
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
        echo "✅ AWS credentials configured"
        echo "   Account: $ACCOUNT_ID"
        echo "   User: $USER_ARN"
    else
        echo "⚠️  AWS credentials not configured or invalid"
        echo "   Run: aws configure"
    fi
else
    echo "⚠️  AWS CLI not installed"
    echo "   You'll need to configure AWS credentials manually"
fi
echo ""

# Step 6: Verify .env configuration
echo "🔍 Step 6: Verifying configuration..."
if [ -f ".env" ]; then
    ENDPOINT=$(grep DSQL_CLUSTER_ENDPOINT .env | cut -d '=' -f2)
    if [ "$ENDPOINT" = "your-cluster-endpoint.dsql.us-east-1.on.aws" ] || [ -z "$ENDPOINT" ]; then
        echo "⚠️  DSQL_CLUSTER_ENDPOINT not configured in .env"
        echo "   Please update .env with your actual cluster endpoint"
        echo ""
        echo "   To get your endpoint:"
        echo "   1. Run the GitHub Actions workflow 'Test Action - Create DSQL Cluster'"
        echo "   2. Copy the endpoint from the workflow output"
        echo "   3. Update DSQL_CLUSTER_ENDPOINT in .env"
    else
        echo "✅ DSQL_CLUSTER_ENDPOINT is configured"
        echo "   Endpoint: $ENDPOINT"
    fi
else
    echo "❌ .env file not found"
fi
echo ""

# Final instructions
echo "=============================="
echo "✅ Setup Complete!"
echo "=============================="
echo ""
echo "Next steps:"
echo ""
echo "1. If you haven't already, get your DSQL cluster endpoint:"
echo "   - Run the GitHub Actions workflow"
echo "   - Copy the cluster endpoint from the output"
echo "   - Update DSQL_CLUSTER_ENDPOINT in .env"
echo ""
echo "2. Make sure AWS credentials are configured:"
echo "   - Run: aws configure"
echo "   - Or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
echo ""
echo "3. Start the application:"
echo "   make run"
echo "   or"
echo "   go run main.go"
echo ""
echo "4. Test the API:"
echo "   curl http://localhost:8080/health"
echo ""
echo "5. Open Swagger UI:"
echo "   http://localhost:8080/swagger/index.html"
echo ""
echo "For more detailed instructions, see SETUP-GUIDE.md"
echo ""

