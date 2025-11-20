package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config holds all configuration for the application
type Config struct {
	Server   ServerConfig
	AWS      AWSConfig
	Database DatabaseConfig
	App      AppConfig
}

// ServerConfig contains server-related configuration
type ServerConfig struct {
	Port string
}

// AWSConfig contains AWS-related configuration
type AWSConfig struct {
	Region string
}

// DatabaseConfig contains database connection configuration
type DatabaseConfig struct {
	Endpoint        string
	DatabaseName    string
	User            string
	Password        string
	AuthMethod      string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime int
}

// AppConfig contains application-level configuration
type AppConfig struct {
	LogLevel string
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	// Try to load .env file (ignore error if it doesn't exist)
	_ = godotenv.Load()

	config := &Config{
		Server: ServerConfig{
			Port: getEnv("PORT", "8080"),
		},
		AWS: AWSConfig{
			Region: getEnv("AWS_REGION", "us-east-1"),
		},
		Database: DatabaseConfig{
			Endpoint:        getEnv("DSQL_CLUSTER_ENDPOINT", ""),
			DatabaseName:    getEnv("DSQL_DATABASE_NAME", "testdb"),
			User:            getEnv("DSQL_USER", "admin"),
			Password:        getEnv("DSQL_PASSWORD", ""),
			AuthMethod:      getEnv("AUTH_METHOD", "iam"),
			MaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 5),
			ConnMaxLifetime: getEnvAsInt("DB_CONN_MAX_LIFETIME", 300),
		},
		App: AppConfig{
			LogLevel: getEnv("LOG_LEVEL", "info"),
		},
	}

	// Validate required fields
	if config.Database.Endpoint == "" {
		return nil, fmt.Errorf("DSQL_CLUSTER_ENDPOINT is required")
	}

	return config, nil
}

// getEnv reads an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt reads an environment variable as an integer or returns a default value
func getEnvAsInt(key string, defaultValue int) int {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return defaultValue
	}
	return value
}

