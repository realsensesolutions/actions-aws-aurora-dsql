package database

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/actions-aws-aurora-dsql/backend/config"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/rds/auth"
	_ "github.com/lib/pq"
)

// DB is the global database connection
var DB *sql.DB

// Connect establishes a connection to the Aurora DSQL database
func Connect(cfg *config.Config) error {
	var connStr string
	var err error

	if cfg.Database.AuthMethod == "iam" {
		// Use AWS IAM authentication
		connStr, err = buildIAMConnectionString(cfg)
		if err != nil {
			return fmt.Errorf("failed to build IAM connection string: %w", err)
		}
	} else {
		// Use password authentication
		connStr = buildPasswordConnectionString(cfg)
	}

	// Open database connection
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("failed to open database connection: %w", err)
	}

	// Configure connection pool
	DB.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	DB.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	DB.SetConnMaxLifetime(time.Duration(cfg.Database.ConnMaxLifetime) * time.Second)

	// Test the connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := DB.PingContext(ctx); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("✅ Successfully connected to Aurora DSQL database")

	// Initialize schema
	if err := initSchema(); err != nil {
		return fmt.Errorf("failed to initialize schema: %w", err)
	}

	return nil
}

// buildIAMConnectionString creates a connection string using AWS IAM authentication
func buildIAMConnectionString(cfg *config.Config) (string, error) {
	ctx := context.Background()

	// Load AWS configuration
	awsCfg, err := awsconfig.LoadDefaultConfig(ctx,
		awsconfig.WithRegion(cfg.AWS.Region),
	)
	if err != nil {
		return "", fmt.Errorf("failed to load AWS config: %w", err)
	}

	// Build the endpoint with port for auth token generation
	// AWS IAM auth requires endpoint in format "hostname:port"
	endpointWithPort := fmt.Sprintf("%s:5432", cfg.Database.Endpoint)

	// Build the authentication token
	authToken, err := auth.BuildAuthToken(
		ctx,
		endpointWithPort,
		cfg.AWS.Region,
		cfg.Database.User,
		awsCfg.Credentials,
	)
	if err != nil {
		return "", fmt.Errorf("failed to build auth token: %w", err)
	}

	// Build connection string
	connStr := fmt.Sprintf(
		"host=%s port=5432 user=%s password=%s dbname=%s sslmode=require",
		cfg.Database.Endpoint,
		cfg.Database.User,
		authToken,
		cfg.Database.DatabaseName,
	)

	return connStr, nil
}

// buildPasswordConnectionString creates a connection string using password authentication
func buildPasswordConnectionString(cfg *config.Config) string {
	return fmt.Sprintf(
		"host=%s port=5432 user=%s password=%s dbname=%s sslmode=require",
		cfg.Database.Endpoint,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.DatabaseName,
	)
}

// initSchema creates the necessary tables if they don't exist
func initSchema() error {
	schema := `
	CREATE TABLE IF NOT EXISTS items (
		id SERIAL PRIMARY KEY,
		title VARCHAR(255) NOT NULL,
		description TEXT,
		completed BOOLEAN DEFAULT FALSE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE INDEX IF NOT EXISTS idx_items_completed ON items(completed);
	`

	_, err := DB.Exec(schema)
	if err != nil {
		return fmt.Errorf("failed to create schema: %w", err)
	}

	log.Println("✅ Database schema initialized")
	return nil
}

// Close closes the database connection
func Close() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}
