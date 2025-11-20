.PHONY: help install run build swagger clean test docker-build docker-run

# Default target
help:
	@echo "Available commands:"
	@echo "  make install      - Install dependencies"
	@echo "  make swagger      - Generate Swagger documentation"
	@echo "  make run          - Run the application"
	@echo "  make build        - Build the application"
	@echo "  make test         - Run tests"
	@echo "  make clean        - Clean build artifacts"

# Install dependencies
install:
	@echo "Installing dependencies..."
	go mod download
	go install github.com/swaggo/swag/cmd/swag@latest

# Generate Swagger documentation
swagger:
	@echo "Generating Swagger documentation..."
	@if command -v swag > /dev/null; then \
		swag init -g main.go --output ./docs; \
	else \
		$$(go env GOPATH)/bin/swag init -g main.go --output ./docs; \
	fi

# Run the application
run: swagger
	@echo "Starting application..."
	go run main.go

# Build the application
build: swagger
	@echo "Building application..."
	go build -o bin/api main.go

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf bin/
	rm -rf docs/
	go clean

