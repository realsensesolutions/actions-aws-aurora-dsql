# Aurora DSQL Test API

A simple CRUD REST API built with Go and Gin framework to test AWS Aurora DSQL database operations. This backend includes Swagger documentation for easy testing and exploration of the API endpoints.

## 📋 Prerequisites

- Go 1.21 or higher
- AWS Account with Aurora DSQL cluster (created via the GitHub Actions workflow)
- AWS CLI configured with appropriate credentials
- Make (optional, for using Makefile commands)

## 🚀 Quick Start

### 1. Clone and Navigate

```bash
cd backend
```

### 2. Install Dependencies

```bash
# Using Make
make install

# Or manually
go mod download
go install github.com/swaggo/swag/cmd/swag@latest
```

### 3. Configure Environment

Copy the example environment file and fill in your values:

```bash
cp env.example .env
```

Edit `.env` with your Aurora DSQL configuration (see Configuration section below).

### 4. Generate Swagger Documentation

```bash
make swagger

# Or manually
swag init -g main.go --output ./docs
```

### 5. Run the Application

```bash
# Using Make
make run

# Or manually
go run main.go
```

The API will start on `http://localhost:8080` and Swagger UI will be available at `http://localhost:8080/swagger/index.html`.

## ⚙️ Configuration

### Getting Values from GitHub Actions

After running the `test-action.yml` workflow, you'll get several outputs. Here's how to use them:

1. **DSQL_CLUSTER_ENDPOINT**: This is the main value you need from the `cluster_endpoint` output
2. **AWS_REGION**: The region where your DSQL cluster is deployed (e.g., `us-east-1`)

### Environment Variables

Create a `.env` file based on `env.example`:

```env
# Server Configuration
PORT=8080

# AWS Configuration
AWS_REGION=us-east-1

# Aurora DSQL Configuration
DSQL_CLUSTER_ENDPOINT=your-cluster-endpoint.dsql.us-east-1.on.aws
DSQL_DATABASE_NAME=testdb
DSQL_USER=admin

# Authentication Method
AUTH_METHOD=iam  # Use 'iam' for production, 'password' for testing

# Connection Pool Settings
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300

# Application Settings
LOG_LEVEL=info
```

### Authentication Methods

#### IAM Authentication (Recommended)

Set `AUTH_METHOD=iam` in your `.env` file. This uses AWS IAM credentials to authenticate with the database. Ensure your AWS credentials are configured:

```bash
# Using AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_SESSION_TOKEN=your_session_token  # If using temporary credentials
```

#### Password Authentication

Set `AUTH_METHOD=password` and provide `DSQL_PASSWORD` in your `.env` file. Note: Not recommended for production use.

## 📚 API Documentation

### Swagger UI

Once the server is running, visit:
```
http://localhost:8080/swagger/index.html
```

### Available Endpoints

#### Health Check
- `GET /health` - Check API and database health

#### Items CRUD
- `GET /api/v1/items` - List all items
- `GET /api/v1/items/:id` - Get a specific item
- `POST /api/v1/items` - Create a new item
- `PUT /api/v1/items/:id` - Update an item
- `DELETE /api/v1/items/:id` - Delete an item

### Example Requests

#### Create an Item
```bash
curl -X POST http://localhost:8080/api/v1/items \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Item",
    "description": "This is a test item",
    "completed": false
  }'
```

#### Get All Items
```bash
curl http://localhost:8080/api/v1/items
```

#### Update an Item
```bash
curl -X PUT http://localhost:8080/api/v1/items/1 \
  -H "Content-Type: application/json" \
  -d '{
    "completed": true
  }'
```

#### Delete an Item
```bash
curl -X DELETE http://localhost:8080/api/v1/items/1
```

## 🏗️ Project Structure

```
backend/
├── config/           # Configuration management
│   └── config.go
├── database/         # Database connection and schema
│   └── connection.go
├── handlers/         # HTTP request handlers
│   ├── health.go
│   └── items.go
├── models/           # Data models and request/response structures
│   └── item.go
├── docs/             # Generated Swagger documentation
├── main.go           # Application entry point
├── go.mod            # Go module definition
├── go.sum            # Go module checksums
├── Makefile          # Build and run commands
├── Dockerfile        # Docker container definition
├── env.example       # Example environment configuration
└── README.md         # This file
```

## 🛠️ Development

### Available Make Commands

```bash
make help       # Show all available commands
make install    # Install dependencies
make swagger    # Generate Swagger documentation
make run        # Run the application
make build      # Build the application binary
make test       # Run tests
make clean      # Clean build artifacts
```

### Building for Production

```bash
# Build binary
make build

# The binary will be created at ./bin/api
./bin/api
```

### Running with Docker

```bash
# Build Docker image
docker build -t aurora-dsql-api .

# Run container
docker run -p 8080:8080 --env-file .env aurora-dsql-api
```

## 🔍 Testing the Database Connection

1. Start the server
2. Check the health endpoint:
   ```bash
   curl http://localhost:8080/health
   ```
3. If the database connection is successful, you'll see:
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

## 📊 Database Schema

The application automatically creates a simple `items` table:

```sql
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🐛 Troubleshooting

### Connection Issues

1. **"Failed to connect to database"**
   - Verify `DSQL_CLUSTER_ENDPOINT` is correct
   - Check AWS credentials are properly configured
   - Ensure the DSQL cluster is running
   - Verify network connectivity and security group rules

2. **"Failed to build auth token"**
   - Check AWS credentials have the necessary IAM permissions
   - Verify `AWS_REGION` matches your DSQL cluster region
   - Try using password authentication for testing

3. **"Context deadline exceeded"**
   - Check if the DSQL cluster is accessible from your network
   - Verify VPC and security group configurations
   - Try increasing connection timeout values

### Swagger Documentation Not Showing

1. Make sure to run `make swagger` or `swag init` before starting the server
2. Check that the `docs/` directory exists and contains generated files
3. Verify you're accessing the correct URL: `http://localhost:8080/swagger/index.html`

## 📝 Notes

- This is a test/development application. For production use, consider:
  - Adding authentication and authorization
  - Implementing rate limiting
  - Adding comprehensive error handling
  - Setting up proper logging and monitoring
  - Using connection pooling optimization
  - Implementing database migrations

## 🔗 Related Resources

- [AWS Aurora DSQL Documentation](https://docs.aws.amazon.com/aurora-dsql/)
- [Gin Web Framework](https://gin-gonic.com/)
- [Swag - Swagger for Go](https://github.com/swaggo/swag)
- [AWS SDK for Go v2](https://aws.github.io/aws-sdk-go-v2/)

## 📄 License

MIT

